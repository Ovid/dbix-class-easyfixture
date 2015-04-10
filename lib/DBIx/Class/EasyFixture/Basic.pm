package DBIx::Class::EasyFixture::Basic;
# ABSTRACT: Basic, simple EasyFixture class

=head1 SYNOPSIS

    use DBIx::Class::EasyFixture::Basic;

    my $fixtures = DBIx::Class::EasyFixture::Basic->new(
        schema => $schema,
        definitions => {
            bob => {
                new   => 'Person',
                using => {
                    name  => 'Bob',
                    email => 'bob@example.com',
                }
            },
        }
    );

=head1 DESCRIPTION

Basic implementation of a EasyFixture class. You provide the
C<definitions> when the object is created, and the 
class takes care of the required C<get_definition>
and C<all_fixture_names>.

=head1 METHODS

The class inherits all methods of L<DBIx::Class::EasyFixture>, plus the following.

=head2 new()

Inherit all the arguments of L<DBIx::Class::EasyFixture>, plus requires 
a C<definitions> hash ref.

=head2 get_definition($name)

Returns the definition associated with the provided C<$name>.

=head2 all_fixture_names()

Returns all the fixture names.

=cut

use strict;
use warnings;

use Moose;

extends 'DBIx::Class::EasyFixture';

has "definitions" => (
    isa => 'HashRef',
    traits => [ 'Hash' ],
    is => 'ro',
    required => 1,
    handles => {
        get_definition => 'get',
        all_fixture_names => 'keys',
    },
);

__PACKAGE__->meta->make_immutable;

1;
