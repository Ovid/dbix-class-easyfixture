package DBIx::Class::EasyFixture;

our $VERSION = '0.01';
use Moose;
use Carp;
use aliased 'DBIx::Class::EasyFixture::Definition';
use namespace::autoclean;

has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);
has '_in_transaction' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    writer  => '_set_in_transaction',
);
has '_cache' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_fixture   => 'set',
        _get_result    => 'get',
        _clear         => 'clear',
        fixture_loaded => 'exists',
    },
);

sub load {
    my ( $self, @fixtures ) = @_;
    unless ( $self->_in_transaction ) {
        $self->schema->txn_begin;
        $self->_set_in_transaction(1);
    }
    foreach my $fixture (@fixtures) {
        my $definition = $self->_get_definition_object($fixture);
        if ( my $group = $definition->group ) {
            $self->load(@$group);
        }
        else {
            $self->_load($definition);
        }
    }
    return 1;
}

sub _get_definition_object {
    my ( $self, $fixture ) = @_;
    return Definition->new(
        {   name       => $fixture,
            definition => $self->get_definition($fixture),
            fixtures   => { map { $_ => 1 } $self->all_fixture_names },
        }
    );
}

sub get_result {
    my ( $self, $fixture ) = @_;

    unless ( $self->fixture_loaded($fixture) ) {
        carp("Fixture '$fixture' was never loaded");
        return;
    }
    return $self->_get_result($fixture);
}

sub _get_object {
    my ( $self, $definition ) = @_;

    my $name   = $definition->name;
    my $object = $self->_get_result($name);
    unless ($object) {
        my $args = $definition->constructor_data;
        if ( my $requires = $definition->requires ) {
            while ( my ( $parent, $methods ) = each %$requires ) {
                my $other = $self->_get_result($parent)
                    or croak("Panic: required object '$parent' not loaded");
                my ( $our, $their ) = @{$methods}{qw/our their/};
                $args->{$our} = $other->$their;
            }
        }
        $object = $self->schema->resultset( $definition->resultset_class )
          ->create( $definition->constructor_data );
        $self->_set_fixture( $name, $object );
    }
    return $object;
}

sub _load {
    my ( $self, $definition ) = @_;

    if ( my $requires = $definition->requires ) {
        $self->_load_previous_fixtures($requires);
    }

    my $object = $self->_get_object($definition);

    if ( my $next = $definition->next ) {
        $self->_load_next_fixtures($next);
    }
    return $object;
}

sub _load_previous_fixtures {
    my ( $self, $requires ) = @_;

    foreach my $parent ( keys %$requires ) {
        $self->_load( $self->_get_definition_object($parent) );
    }
}

sub _load_next_fixtures {
    my ( $self, $next ) = @_;

    # check for circular definitions!
    foreach my $fixture (@$next) {
        my $definition = $self->_get_definition_object($fixture);
        my %data       = %{ $definition->constructor_data };
        if ( my $requires = $definition->requires ) {
            while ( my ( $parent, $methods ) = each %$requires ) {
                my $related_object = $self->_get_result($parent)
                    || $self->_load($self->_get_definition_object($parent))
                    || croak("Panic: related object '$parent' not loaded");
                my $related_method = $methods->{their};
                $data{ $methods->{our} } = $related_object->$related_method;
            }
        }
        $self->_load(
            Definition->new(
                {   name       => $fixture,
                    definition => {
                        new   => $definition->resultset_class,
                        using => \%data,
                    },
                    fixtures   => { map { $_ => 1 } $self->all_fixture_names },
                }
            )
        );
    }
}

sub unload {
    my $self = shift;
    if ( $self->_in_transaction ) {
        $self->schema->txn_rollback;
        $self->_clear;
        $self->_set_in_transaction(0);
    }
    else {
        # XXX I don't think I really need this
        #carp("finish() called without load()");
    }
    return 1;
}

sub all_fixture_names {
    croak("You must override all_fixture_names() in a subclass");
}

sub get_definition {
    croak("You must override get_definition() in a subclass");
}

sub DEMOLISH {
    my $self = shift;
    $self->unload;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::Class::EasyFixture - Easy-to-use DBIx::Class fixtures.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::EasyFixture';

    sub get_fixture       { ... }
    sub all_fixture_names { ... }

And in your test code:

    my $fixtures = My::Fixtures->new( { schema => $schema } );
    $fixtures->load('some_fixture');

    # run your tests

    $fixtures->unload;

Note that C<unload> will be called for you if your fixture object falls out of
scope.

=head1 DESCRIPTION

This is C<ALPHA> code. Documentation is on its way, including a tutorial. For
now, you'll have to read the tests. You can read F<t/lib/My/Fixtures.pm> to
see how fixtures are defined.

I wanted an easier way to load fixtures for L<DBIx::Class> code. I looked at
L<DBIx::Class::Fixtures> and it made a lot of assumptions that, while
appropriate for some, is not what I wanted (such as the necessity of storing
fixtures in JSON files), and had a reliance on knowing the values of primary
keys, I wrote this to make it easier to define and load L<DBIx::Class>
fixtures for tests.

=head1 METHODS

=head2 C<new>

    my $fixtures = Subclass::Of::DBIx::Class::EasyFixture->new({
        schema => $dbix_class_schema_instance,
    });

This creates and returns a new instance of your C<DBIx::Class::EasyFixture> subclass.

=head2 C<all_fixture_names>

    my @fixture_names = $fixtures->all_fixture_names;

Must overridden in your subclass. Should return a list (not an array ref!) of
all fixture names available. This is used internally to generate error
messages if a fixture attempts to reference a non-existent fixture in its
C<next> or C<requires> section.

=head2 C<get_definition>

    my $definition = $fixtures->get_definition($fixture_name);

Must be overridden in a subclass. Should return the fixture definition for the
fixture name passed in. Should return C<undef> if the fixture is not found.

=head2 C<get_result>

    my $dbic_result_object = $fixtures->get_result($fixture_name);

Returns the C<DBIx::Class::Result> object for the given fixture name. Will
C<carp> if the fixture wasn't loaded (this may become a fatal error in future
versions).

=head2 C<load>

    $fixtures->load(@list_of_fixture_names);

Attempts to load all fixtures passed to it. If a transaction has not already
been started, it will be started now. This method may be called multiple
times.

=head2 C<unload>

    $fixtures->unload;

Rolls back the transaction started with C<load>

=head2 C<fixture_loaded>

    if ( $fixtures->fixture_loaded($fixture_name) ) {
        ...
    }

Returns a boolean value indicating whether or not the given fixture was
loaded.

=head1 TUTORIAL

See L<DBIx::Class::EasyFixture::Tutorial>.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 TODO

=over 4

=item * Prevent circular fixtures

Currently it's very easy to define circular dependencies. We'll worry about
that later when it becomes more clear how to best handle them.

=item * Better load information

Track what fixtures are requested and what fixtures are loaded (and in which
order).  This makes for better error reporting.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-simplefixture
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-EasyFixture>.  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::EasyFixture

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-EasyFixture>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-EasyFixture>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-EasyFixture>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-EasyFixture/>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to L<http://www.allaroundtheworld.fr/> for sponsoring this work.

See also L<http://search.cpan.org/dist/DBIx-Class-Fixtures/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
