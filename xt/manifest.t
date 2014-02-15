#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest(
    { filter => [qr/(?:\.git|errors.err|\.bak|\.DS_Store|\.sw.$)/] } );
