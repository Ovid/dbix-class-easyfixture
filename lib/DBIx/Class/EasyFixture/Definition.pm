package DBIx::Class::EasyFixture::Definition;
use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use Storable 'dclone';
use namespace::autoclean;

our $VERSION = '0.02';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'definition' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'fixtures' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    handles => {
        fixture_exists => 'exists',
    },
);

has 'group' => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my $args = $_[0];
    if ( 'HASH' ne ref $_[0] ) {
        $args = {@_};
    }
    if ( 'ARRAY' eq ref $args->{definition} ) {
        $args->{group}      = $args->{definition};
        $args->{definition} = {};
    }
    $self->$orig( dclone($args) );
};

sub BUILD {
    my $self = shift;

    unless ( $self->group ) {
        $self->_validate_keys;
        $self->_validate_class_and_data;
        $self->_validate_next;
        $self->_validate_required_objects;
    }
}

sub resultset_class  { shift->definition->{new} }
sub constructor_data { shift->definition->{using} }
sub next             { shift->definition->{next} }
sub requires         { shift->definition->{requires} }

sub _validate_keys {
    my $self       = shift;
    my $name       = $self->name;
    my %definition = %{ $self->definition };    # shallow copy currently ok
    unless ( keys %definition ) {
        croak("Fixture '$name' had no keys");
    }
    delete @definition{qw/group new using next requires/};
    if ( my @unknown = sort keys %definition ) {
        croak("Fixture '$name' had unknown keys: @unknown");
    }
}

sub _validate_class_and_data {
    my $self = shift;

    my $class = $self->resultset_class;
    my $data  = $self->constructor_data;

    if ( $class xor $data ) {
        my $found   = $class ? 'new'  : 'using';
        my $missing = $class ? 'using' : 'new';
        my $name    = $self->name;
        croak("Fixture '$name' had a '$found' without a '$missing'");
    }
}

sub _validate_next {
    my $self = shift;
    my $next = $self->next or return;

    $next = [$next] unless 'ARRAY' eq ref $next;
    my $name = $self->name;
    foreach my $child (@$next) {
        if ( !defined $child ) {
            croak("Fixture '$name' had an undefined element in 'next'");
        }
        if ( ref $child ) {
            croak("Fixture '$name' had non-string elements in 'next'");
        }
        unless ( $self->fixture_exists($child) ) {
            croak("Fixture '$name' lists a non-existent fixture in 'next': '$child'");
        }
    }
}

sub _validate_required_objects {
    my $self = shift;

    my $name = join '.' => $self->name, $self->resultset_class, 'requires';

    my $requires = $self->requires or return;
    unless ( 'HASH' eq ref $requires ) {
        croak("$name does not appear to be a hashref");
    }

    # XXX don't use a while loop here because we might rewrite requires() and
    # that would break the iterator
    foreach my $parent (keys %$requires) {
        my $methods = $requires->{$parent};
        unless ( $self->fixture_exists($parent) ) {
            croak("Fixture '$name' requires a non-existent fixture '$parent'");
        }
        if ( !ref $methods ) {
            # they used a single key and it matched
            $self->definition->{requires}{$parent} = { our => $methods, their => $methods };
            next;
        }
        if ( my @bad_keys = grep { !/^(?:our|their)$/ } keys %$methods ) {
            croak("'$name' had bad keys: @bad_keys");
        }
        unless ( exists $methods->{our} ) {
            croak("'$name' requires 'our'");
        }
        unless ( exists $methods->{their} ) {
            croak("'$name' requires 'their'");
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::Class::EasyFixture::Definition - Validate fixture definitions

=head2 DESCRIPTION

For internal use only. Maybe I'll document it some day.
