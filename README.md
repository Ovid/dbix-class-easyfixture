# NAME

DBIx::Class::EasyFixture - Easy-to-use DBIx::Class fixtures.

# VERSION

Version 0.03

# SYNOPSIS

    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::EasyFixture';

    sub get_fixture       { ... }
    sub all_fixture_names { ... }

And in your test code:

    my $fixtures    = My::Fixtures->new( { schema => $schema } );
    my $dbic_object = $fixtures->load('some_fixture');

    # run your tests

    $fixtures->unload;

Note that `unload` will be called for you if your fixture object falls out of
scope.

# DESCRIPTION

The latest version of this is always at
[https://github.com/Ovid/dbix-class-easyfixture](https://github.com/Ovid/dbix-class-easyfixture).

This is `ALPHA` code. Documentation is on its way, including a tutorial. For
now, you'll have to read the tests. You can read `t/lib/My/Fixtures.pm` to
see how fixtures are defined.

I wanted an easier way to load fixtures for [DBIx::Class](https://metacpan.org/pod/DBIx::Class) code. I looked at
[DBIx::Class::Fixtures](https://metacpan.org/pod/DBIx::Class::Fixtures) and it made a lot of assumptions that, while
appropriate for some, is not what I wanted (such as the necessity of storing
fixtures in JSON files), and had a reliance on knowing the values of primary
keys, I wrote this to make it easier to define and load [DBIx::Class](https://metacpan.org/pod/DBIx::Class)
fixtures for tests.

# METHODS

## `new`

    my $fixtures = Subclass::Of::DBIx::Class::EasyFixture->new({
        schema => $dbix_class_schema_instance,
    });

This creates and returns a new instance of your `DBIx::Class::EasyFixture`
subclass. All fixture definitions are validated at this time and the
constructor will `croak()` with a useful error message upon validation
failure.

## `all_fixture_names`

    my @fixture_names = $fixtures->all_fixture_names;

Must overridden in your subclass. Should return a list (not an array ref!) of
all fixture names available. This is used internally to generate error
messages if a fixture attempts to reference a non-existent fixture in its
`next` or `requires` section.

## `get_definition`

    my $definition = $fixtures->get_definition($fixture_name);

Must be overridden in a subclass. Should return the fixture definition for the
fixture name passed in. Should return `undef` if the fixture is not found.

## `get_result`

    my $dbic_result_object = $fixtures->get_result($fixture_name);

Returns the `DBIx::Class::Result` object for the given fixture name. Will
`carp` if the fixture wasn't loaded (this may become a fatal error in future
versions).

## `load`

    my @dbic_objects = $fixtures->load(@list_of_fixture_names);

Attempts to load all fixtures passed to it. If a transaction has not already
been started, it will be started now. This method may be called multiple
times and it returns the fixtures loaded. If called in scalar context, only
returns the first fixture loaded.

## `unload`

    $fixtures->unload;

Rolls back the transaction started with `load`

## `fixture_loaded`

    if ( $fixtures->fixture_loaded($fixture_name) ) {
        ...
    }

Returns a boolean value indicating whether or not the given fixture was
loaded.

# FIXTURES

If the following is unclear, see [DBIx::Class::EasyFixture::Tutorial](https://metacpan.org/pod/DBIx::Class::EasyFixture::Tutorial).

The `get_definition($fixture_name)` method must always return a fixture
definition. The definition must be either a fixture group or a fixture
builder.

A fixture group is an array reference containing a list of fixture names. For
example, `$fixture->get_definition('all_people')` might return:

    [qw/ person_1 person_2 person_2 /]

A fixture builder must return a hash reference with the one or more of the
following keys:

- `new` (required)

    A `DBIx::Class` result source name.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            }
        }

    Internally, the above will do something similar to this:

        $schema->resultset($definition->{name})
               ->create($definition->{using});

- `using` (required)

    A hashref of key/value pairs that will be used to create the `DBIx::Class`
    result source referred to by the `new` key.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            }
        }

- `next` (optional)

    If present, this must point to an array reference of fixture names (in other
    words, a fixture group). These fixtures will then be built _after_ the
    current fixture is built.

        {
            new   => 'Person',
            using => {
                name  => 'Bob',
                email => 'bob@example.com',
            },
            next => [@list_of_fixture_names],
        }

- `requires` (optional)

    Must point to either a scalar of an attribute name or a hash mapping of
    attribute names.

    Many fixtures require data from another fixture. For example, a customer might
    require a person object being built and the following won't work:

        {
            new   => 'Customer',
            using => {
                first_purchase => $datetime_object,
                person_id      => 'some_person.person_id',
            }
        }

    Assuming we already have a `Person` fixture defined and it's named
    `some_person` and its ID is named `id`, we can do this:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person => {
                    our   => 'person_id',
                    their => 'id',
                },
            },
        }

    If you prefer, you can _inline_ the `requires` into the `using` key. You
    may find this syntax cleaner:

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => { some_person => 'id' },
            },
        }

    The `our` key refers to the attribute for the `Customer` fixture and the
    `their` key refers to the attribute of the `Person` fixture. As a
    convenience, if both attributes have the same name, you can omit that hashref
    and just use the attribute name:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person => 'person_id',
            },
        }

    And multiple `requires` can be specified:

        {
            new      => 'Customer',
            using    => { first_purchase => $datetime_object },
            requires => {
                some_person     => 'person_id',
                primary_contact => 'contact_id',
            },
        }

    Or you can skip the `requires` block entirely and write the above like this
    (which is now the preferred syntax, but whatever floats your boat):

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => { some_person     => 'person_id' },
                contact_id     => { primary_contact => 'contact_id' },
            },
        }

    If both the current fixture and the other fixture it requires have the same
    name for the attribute, a reference to the other fixture name (scalar
    reference) will suffice:

        {
            new      => 'Customer',
            using    => {
                first_purchase => $datetime_object,
                person_id      => \'some_person',
                contact_id     => \'primary_contact',
            },
        }
    The above will construct the fixture like this:

        $schema->resultset('Customer')->create({
            first_purchase  => $datetime_object,
            person_id       => $person->person_id,
            primary_contact => $contact->contact_id,
        });

When writing a fixture builder, remember that `requires` are always built
before the current fixture and `next` is also built after the current
fixture.

# TUTORIAL

See [DBIx::Class::EasyFixture::Tutorial](https://metacpan.org/pod/DBIx::Class::EasyFixture::Tutorial).

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

# TODO

- Prevent circular fixtures

    Currently it's very easy to define circular dependencies. We'll worry about
    that later when it becomes more clear how to best handle them.

- Better load information

    Track what fixtures are requested and what fixtures are loaded (and in which
    order).  This makes for better error reporting.

# BUGS

Please report any bugs or feature requests to `bug-dbix-class-simplefixture
at rt.cpan.org`, or through the web interface at
[https://github.com/Ovid/dbix-class-easyfixture/issues](https://github.com/Ovid/dbix-class-easyfixture/issues).  I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::EasyFixture
    perldoc DBIx::Class::EasyFixture::Tutorial

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://github.com/Ovid/dbix-class-easyfixture/issues](https://github.com/Ovid/dbix-class-easyfixture/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/DBIx-Class-EasyFixture](http://annocpan.org/dist/DBIx-Class-EasyFixture)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DBIx-Class-EasyFixture](http://cpanratings.perl.org/d/DBIx-Class-EasyFixture)

- Search CPAN

    [http://search.cpan.org/dist/DBIx-Class-EasyFixture/](http://search.cpan.org/dist/DBIx-Class-EasyFixture/)

# ACKNOWLEDGEMENTS

Many thanks to [http://www.allaroundtheworld.fr/](http://www.allaroundtheworld.fr/) for sponsoring this work.

See also [http://search.cpan.org/dist/DBIx-Class-Fixtures/](http://search.cpan.org/dist/DBIx-Class-Fixtures/).

# LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
