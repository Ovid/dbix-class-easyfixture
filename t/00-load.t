#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::EasyFixture' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::EasyFixture $DBIx::Class::EasyFixture::VERSION, Perl $], $^X" );
