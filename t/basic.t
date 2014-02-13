use Test::Most;

{
    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::SimpleFixture';
}

pass('start working');

done_testing;
