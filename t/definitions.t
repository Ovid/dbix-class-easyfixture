use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;
use aliased 'DBIx::Class::SimpleFixture::Definition';
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
        Definition->new(
            {   name       => $name,
                definition => $fixtures->get_definition($name),
            }
        );
    }
    'Definitions should be valid for all defined fixtures';
}

my $definition = Definition->new(
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
eq_or_diff $definition->next, [qw/basic_customer/],
  '... and the correct next';
ok !defined $definition->requires,
  '... and no requirements if they are not defined';

subtest 'exceptions' => sub {
    subtest 'definition class and data' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { new => 'Foo' }
            );
        }
        qr/Fixture 'bob' had a 'new' without a 'using'/,
          'Having a definition class without constructor data should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { using => { name => 'Foo' } }
            );
        }
        qr/Fixture 'bob' had a 'using' without a 'new'/,
          'Having constructor data without a class should fail';
    };
    subtest 'definition keys' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => {}
            );
        }
        qr/Fixture 'bob' had no keys/,
          'Having a definition data without keys should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { foo => 1, bar => 2 }
            );
        }
        qr/Fixture 'bob' had unknown keys: bar foo/,
          'Having a definition data with unknown keys should fail';
    };
    subtest 'definition next' => sub {
        my %ignore = ( new => 'Foo', using => { bar => 1 } );
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, next => [undef] }
            );
        }
        qr/Fixture 'this' had an undefined element in 'next'/,
          "Undefined elements in 'next' should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, next => [ {} ] }
            );
        }
        qr/Fixture 'this' had non-string elements in 'next'/,
          "Non-string elements in 'next' should fail";
    };
    subtest 'definition requires' => sub {
        my %ignore = ( new => 'Foo', using => { bar => 1 } );
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, requires => [] }
            );
        }
        qr/this.Foo.requires does not appear to be a hashref/,
          "requires() must be a hashref";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            our   => 'foo_id',
                            their => 'foo_id',
                            extra => 'asdf',
                        },
                    },
                }
            );
        }
        qr/'this.Foo.requires' had bad keys: extra/,
          "Unknown keys in requires should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            their => 'foo_id',
                        },
                    },
                }
            );
        }
        qr/'this.Foo.requires' requires 'our'/,
          "Missing 'our' in requires should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            our => 'foo_id',
                        },
                    },
                }
            );
        }
        qr/'this.Foo.requires' requires 'their'/,
          "Missing 'their' in requires should fail";
    };
};

done_testing;
