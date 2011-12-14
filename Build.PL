use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IPC::Share::BDB',
    license             => 'perl',
    dist_author         => q{lbe <lbe@cpan.org>},
    dist_version_from   => 'lib/IPC/Share/BDB.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'IPC::Share::BDB-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
