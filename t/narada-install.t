use t::share; guard my $guard;

require (wd().'/blib/script/narada-install');


my %mock = my %init_mock = (
    prev_version    => undef,
    next_version    => undef,
    files           => [],
    path            => undef,
    allow_downgrade => 0,
    allow_restore   => 0,
    get_path        => 0,
    migrate         => 0,
);
my $module = Test::MockModule->new('main');
$module->mock(load      => sub {
    $mock{prev_version}     = shift;
    $mock{next_version}     = shift;
    $mock{files}            = \@_;
    return 'mocked migrate';
});
$module->mock(get_path  => sub {
    $mock{get_path}++;
    return ['mocked path'];
});
$module->mock(check_path=> sub {
    shift;
    $mock{path}             = shift;
    $mock{allow_downgrade}  = shift;
    $mock{allow_restore}    = shift;
});
$module->mock(migrate   => sub {
    $mock{migrate}++;
});


# - main (parsing args)
%mock = %init_mock;
#   * --nosuch
throws_ok { main(qw( --nosuch )) } qr/Usage/msi, '--nosuch: died with Usage';
#   * --help
#     ** only param
lives_ok { output_like { main(qw( -h                        )) }
    qr/Usage/msi, qr/\A\z/msi, 'Usage on STDOUT' } '-h: normal exit';
lives_ok { output_like { main(qw( --help                    )) }
    qr/Usage/msi, qr/\A\z/msi, 'Usage on STDOUT' } '--help: normal exit';
#     ** with other params
lives_ok { output_like { main(qw( -c file -h --path         )) }
    qr/Usage/msi, qr/\A\z/msi, 'Usage on STDOUT' } '... -h ...: normal exit';
lives_ok { output_like { main(qw( -c file --help --path     )) }
    qr/Usage/msi, qr/\A\z/msi, 'Usage on STDOUT' } '... --help ...:normal exit';
#   * --check
#     ** with incompatible params
throws_ok { main(qw( -c file extra      )) } qr/Usage/msi, '-c file extra: died with Usage';
throws_ok { main(qw( -p -c file         )) } qr/Usage/msi, '-p -c file: died with Usage';
throws_ok { main(qw( -D -c file         )) } qr/Usage/msi, '-D -c file: died with Usage';
throws_ok { main(qw( -R -c file         )) } qr/Usage/msi, '-R -c file: died with Usage';
throws_ok { main(qw( -f file -c file    )) } qr/Usage/msi, '-f file -c file: died with Usage';
#     ** bad file
throws_ok { main(qw( -c file            )) } qr/No such file/msi, '-c file: No such file';
throws_ok { main(qw( -c config          )) } qr/plain file/msi, '-c config: not a plain file';
throws_ok { main(qw( -c /dev/null       )) } qr/plain file/msi, '-c /dev/null: not a plain file';
#     ** bad file syntax
throws_ok { main(qw( -c VERSION         )) } qr/parse error/msi, '-c VERSION: parse error';
throws_ok { main(qw( --check VERSION    )) } qr/parse error/msi, '--check VERSION: parse error';
#     ** good file syntax
lives_ok  { main(qw( -c .release/0.1.0.migrate      )) } '-c .release/0.1.0.migrate: ok';
lives_ok  { main(qw( --check .release/0.1.0.migrate )) } '--check .release/0.1.0.migrate: ok';
#   * --path
#     ** too short path
throws_ok { main(qw( -p                 )) } qr/Usage/msi, '-p: died with Usage';
throws_ok { main(qw( -p 1               )) } qr/Usage/msi, '-p 1: died with Usage';
throws_ok { main(qw( -p 1 2             )) } qr/Usage/msi, '-p 1 2: died with Usage';
throws_ok { main(qw( --path 1 2         )) } qr/Usage/msi, '--path 1 2: died with Usage';
#     ** same start and end versions
lives_ok  { main(qw( -p 1 2 1           )) } '-p 1 2 1: normal exit';
lives_ok  { main(qw( --path 1 2 3 1     )) } '--path 1 2 3 1: normal exit';
is_deeply \%mock, \%init_mock, 'no migration run';
#     ** good path
lives_ok  { main(qw( -p 1 2 3           )) } '-p 1 2 3: normal exit';
is_deeply \%mock, {
    prev_version    => '1',
    next_version    => '3',
    files           => [],
    path            => ['1','2','3'],
    allow_downgrade => 1,
    allow_restore   => 1,
    get_path        => 0,
    migrate         => 1,
}, 'migration was run';
#   * default
#     ** no version
throws_ok { main(qw(                    )) } qr/Usage/msi, '(no params): died with Usage';
throws_ok { main(qw( -D -R -f file      )) } qr/Usage/msi, '-D -R -f file: died with Usage';
#     ** too many params
throws_ok { main(qw( 1 2                )) } qr/Usage/msi, '1 2: died with Usage';
throws_ok { main(qw( -D -R -f file 1 2  )) } qr/Usage/msi, '-D -R -f file 1 2: died with Usage';
#     ** prev_version autodetect
%mock = %init_mock;
main(qw( 1.0.0 ));
is_deeply \%mock, {
    prev_version    => '0.1.0',
    next_version    => '1.0.0',
    files           => [],
    path            => ['mocked path'],
    allow_downgrade => 0,
    allow_restore   => 0,
    get_path        => 1,
    migrate         => 1,
}, 'prev_version detected';
chdir 'tmp' or die "chdir(tmp): $!";
%mock = %init_mock;
main(qw( 1.0.0 ));
is_deeply \%mock, {
    prev_version    => '0.0.0',
    next_version    => '1.0.0',
    files           => [],
    path            => ['mocked path'],
    allow_downgrade => 0,
    allow_restore   => 0,
    get_path        => 1,
    migrate         => 1,
}, 'prev_version INITIAL';
#     ** same start and end versions
%mock = %init_mock;
main(qw( 0.0.0 ));
is_deeply \%mock, \%init_mock, '0.0.0 -> 0.0.0: no migration run';
chdir '..' or die "chdir(..): $!";
%mock = %init_mock;
main(qw( 0.1.0 ));
is_deeply \%mock, \%init_mock, '0.1.0 -> 0.1.0: no migration run';

# - load
#   * no next_version file
#   * only next_version file
#   * next_version and prev_version files, in order
#   * extra files and next_version file, in order
#   * extra files, next_version and prev_version file, in order

# - get_path
#   * no paths
#   * two paths
#   * one path

# - check_path
#   * wrong path (from --path)
#   * path require --allow-downgrade, with/without it
#   * path require --allow-restore, with/without it
#   * path require both --allow-downgrade and --allow-restore, with/without them
#   * path require restoring from backup, with/without it

# - simple functional test:
#       0.0.0 upgrade to   1.1.0
#   * check is VERSION file created and correct
#   * check there are no backups
#       1.1.0 upgrade to   1.2.0
#   * check is VERSION file modified and correct
#   * check backup for 1.1.0 created
#       1.2.0 downgrade to 0.0.0
#   * check is VERSION file removed
#   * check backup for 1.2.0 created
#   * check backup for 1.1.0 updated

# - complex functional test:
#       1.5.0 downgrade to 1.4.0,
#       1.4.0 downgrade to 1.3.0,
#       1.3.0 restore to   1.2.0,
#       1.2.0 downgrade to 1.1.0,
#       1.1.0 downgrade to 0.0.0,
#       0.0.0 upgrade to   2.1.0,
#       2.1.0 upgrade to   2.2.0,
#       2.2.0 upgrade to   2.3.0.
#   * check is all backups was created
#   * test error while first backup
#   * test error while middle backup
#   * test error while middle downgrade
#   * test error while middle upgrade
#   * test canceling restore
#   * test error while restore
#   * test error while restore after error


done_testing();
