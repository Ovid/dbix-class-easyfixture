use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'DBIx::Class::SimpleFixture',
    license            => 'Artistic_2_0',
    dist_author        => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    dist_version_from  => 'lib/DBIx/Class/SimpleFixture.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::Most'    => 0,
        'DBD::SQLite'   => 0,
        'aliased'       => 0,
        'Capture::Tiny' => 0,
    },
    requires => {
        'DBIx::Class' => 0,
        'aliased'     => 0,
    },
    add_to_cleanup     => ['DBIx-Class-SimpleFixture-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
