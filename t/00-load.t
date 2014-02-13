#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::SimpleFixture' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::SimpleFixture $DBIx::Class::SimpleFixture::VERSION, Perl $], $^X" );
