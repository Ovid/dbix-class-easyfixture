package My::Fixtures;
use Moose;
use DateTime;
use namespace::autoclean;
extends 'DBIx::Class::SimpleFixture';

my $birthday = DateTime->new(
    year  => 1983,
    month => 2,
    day   => 12,
);

my %definition_for = (
    person_without_customer => {
        class => 'Person',
        data  => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $birthday,
        },
    },
);

sub get_definition {
    my ( $self, $name ) = @_;
    return $definition_for{$name};
}

__PACKAGE__->meta->make_immutable;

1;
