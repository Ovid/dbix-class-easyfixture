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
        next => [qw/basic_customer/],
    },
    basic_customer => {
        class    => 'Customer',
        data     => { first_purchase => $purchase_date },
        requires => {
            person_with_customer => {
                our   => 'person_id',
                their => 'person_id',
            },
        },
    },
    order_without_items => {
        class    => 'Order',
        data     => { order_date => $purchase_date },
        requires => {
            basic_customer => {
                our   => 'customer_id',
                their => 'customer_id',
            }
        },
    }
);

sub get_definition {
    my ( $self, $name ) = @_;
    return $definition_for{$name};
}

sub all_fixture_names { return keys %definition_for }

__PACKAGE__->meta->make_immutable;

1;
