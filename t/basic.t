use Test::Most;

{
    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::SimpleFixture';
}

my $fix

done_testing;
