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
        new   => 'Person',
        using => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $birthday,
        },
    },

    # these next three are related (person_with_customer, basic_customer,
    # order_without_items)
    person_with_customer => {
        new   => 'Person',
        using => {
            name     => "sally",
            email    => 'person@customer.com',
            birthday => $birthday,
        },
        next => [qw/basic_customer/],
    },
    basic_customer => {
        new      => 'Customer',
        using    => { first_purchase => $purchase_date },
        requires => {
            person_with_customer => {
                our   => 'person_id',
                their => 'person_id',
            },
        },
    },
    order_without_items => {
        new      => 'Order',
        using    => { order_date => $purchase_date },
        requires => {
            basic_customer => {
                our   => 'customer_id',
                their => 'customer_id',
            }
        },
    },

    #
    order_with_items => {
        new      => 'Order',
        using    => { order_date => $purchase_date },
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
