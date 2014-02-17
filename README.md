# NAME

DBIx::Class::EasyFixture - Easy-to-use DBIx::Class fixtures.

# VERSION

Version 0.01

# SYNOPSIS

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

Note that `unload` will be called for you if your fixture object falls out of
scope.

# DESCRIPTION

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

    $fixtures->load(@list_of_fixture_names);

Attempts to load all fixtures passed to it. If a transaction has not already
been started, it will be started now. This method may be called multiple
times.

## `unload`

    $fixtures->unload;

Rolls back the transaction started with `load`

## `fixture_loaded`

    if ( $fixtures->fixture_loaded($fixture_name) ) {
        ...
    }

Returns a boolean value indicating whether or not the given fixture was
loaded.

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
