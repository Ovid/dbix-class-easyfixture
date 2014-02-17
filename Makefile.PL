use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'DBIx-Class-EasyFixture';
all_from 'lib/DBIx/Class/EasyFixture.pm';
author q{Curtis "Ovid" Poe <ovid@cpan.org>};
license 'artistic2';

perl_version 5.008003;

tests_recursive('t');

resources(
    #homepage   => 'http://yourwebsitehere.com',
    #IRC        => 'irc://irc.perl.org/#Example',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'https://github.com/Ovid/dbix-class-easyfixture',
    bugtracker => 'https://github.com/Ovid/dbix-class-easyfixture/issues',
);

configure_requires(
    'Module::Install' => 0,
);

build_requires(
    'Capture::Tiny'            => '0.24',
    'DBD::SQLite'              => '1.40',
    'DateTime'                 => 0,
    'DateTime::Format::SQLite' => 0,
    'Test::Most'               => '0.33',
);

requires(
    'DBIx::Class'          => 0,
    'Moose'                => 0,
    'aliased'              => 0,
    'namespace::autoclean' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
