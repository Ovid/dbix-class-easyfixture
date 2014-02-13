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
my $purchase_date = DateTime->new(
    year  => 2011,
    month => 12,
    day   => 23,
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
    person_with_customer => {
        class => 'Person',
        data  => {
            name     => "sally",
            email    => 'person@customer.com',
            birthday => $birthday,
        },
        with => [qw/basic_customer/],
    },
    basic_customer => {
        class         => 'Customer',
        data          => { first_purchase => $purchase_date },
        want_related  => {
            'Person' => {
                me   => 'person_id',
                them => 'person_id',
            },
        },
    }
);

sub get_definition {
    my ( $self, $name ) = @_;
    return $definition_for{$name};
}

__PACKAGE__->meta->make_immutable;

1;
