use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;
use DBIx::Class::SimpleFixture::Definition;
use DateTime;

my $birthday = DateTime->new(
    year  => 1983,
    month => 2,
    day   => 12,
);

my $schema = Sample::Schema->test_schema;

my $fixtures = My::Fixtures->new( { schema => $schema } );
my @names = $fixtures->all_fixture_names;
foreach my $name (@names) {
    lives_ok {
        DBIx::Class::SimpleFixture::Definition->new(
            {   name       => $name,
                definition => $fixtures->get_definition($name),
            }
        );
    }
    'Definitions should be valid for all defined fixtures';
}

my $definition = DBIx::Class::SimpleFixture::Definition->new(
    {   name       => 'person_with_customer',
        definition => $fixtures->get_definition('person_with_customer')
    }
);
is $definition->name, 'person_with_customer',
  'definitions should return the correct name';
is $definition->resultset_class, 'Person',
  '... and the correct resultset_class';
eq_or_diff $definition->constructor_data,
  { name     => 'sally',
    email    => 'person@customer.com',
    birthday => $birthday,
  },
  '... and the correct data definition';
eq_or_diff $definition->children, [qw/basic_customer/],
  '... and the correct children';
ok !defined $definition->requires,
  '... and no requirements if they are not defined';

done_testing;
