#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 23;
use Test::Exception;

use Narada::Config qw( get_config );

use File::Temp qw( tempdir );
chomp(my $cwd=`pwd`); $ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
chdir tempdir( CLEANUP => 1 )
    and system('narada-new') == 0
    or die "Unable to create project: $!";

my @badvar = ('a b', qw( a:b $a a+b a\b ./ a/./b ../ a/../b dir/ version/ ));

throws_ok { get_config() }          qr/Usage:/,     'no params';
throws_ok { get_config(1, 2) }      qr/Usage:/,     'too many params';

throws_ok { get_config($_) }        qr/bad config:/,
    "bad variable: $_"
    for @badvar;

throws_ok { get_config($_) }        qr/no such config:/,
    "no such config: $_"
    for qw( no_file no_dir/no_file backup/no-file );

SKIP: {
    skip 'non-root user required', 1 if $< == 0;
    chmod 0, 'config/version';
    throws_ok { get_config('version') } qr/open\(config\/version\):/,
        "bad permissions";
    chmod 0644, 'config/version';
}

like get_config('version'), qr/\d/,
    'read version';

Echo('config/empty', q{});
is get_config('empty'), q{}, 'empty';
Echo('config/test', "test\n");
is get_config('test'), "test\n", 'single line with \n';
Echo('config/test-n', "test");
is get_config('test-n'), "test", 'single line without \n';
Echo('config/test_multi', "test\ntest2\n");
is get_config('test_multi'), "test\ntest2\n", 'multi line';
mkdir 'config/testdir' or die "mkdir: $!";
Echo('config/testdir/test', "testdir\n");
is get_config('testdir/test'), "testdir\n", 'variable in directory';

chdir '/';  # work around warnings in File::Temp CLEANUP handler


sub Echo {
    my ($file, $data) = @_;
    open my $fh, '>', $file or die "open: $!";
    print {$fh} $data;
    close $fh or die "close: $!";
    return;
}
