use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'DBIx::Class::EasyFixture',
    license            => 'Artistic_2_0',
    dist_author        => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    dist_version_from  => 'lib/DBIx/Class/EasyFixture.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::Most'    => 0,
        'DBD::SQLite'   => 0,
        'Capture::Tiny' => '0.24',
    },
    requires => {
        'DBIx::Class'          => 0,
        'aliased'              => 0,
        'namespace::autoclean' => 0,
        'Moose'                => 0,
    },
    add_to_cleanup     => ['DBIx-Class-EasyFixture-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources =>
          { repository => 'https://github.com/Ovid/dbix-class-easyfixture' }
    },
);

$builder->create_build_script();
