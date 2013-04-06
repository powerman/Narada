#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 8;
use Test::Exception;

use Narada::Config qw( get_config_line );

use File::Temp qw( tempdir );
chomp(my $cwd=`pwd`); $ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
chdir tempdir( CLEANUP => 1 )
    and system('narada-new') == 0
    or die "Unable to create project: $!";


throws_ok { get_config_line('no_file') }        qr/no such config:/,
    'no such config: no_file';

system('echo > config/empty');
is get_config_line('empty'), q{}, 'empty with \n';
system('echo -n > config/empty-n');
is get_config_line('empty-n'), q{}, 'empty without \n';
system('echo test > config/test');
is get_config_line('test'), 'test', 'single line with \n';
system('echo -n test > config/test-n');
is get_config_line('test-n'), 'test', 'single line without \n';
system('echo -ne "test\n  \n  \n" > config/test_multi_newline');
is get_config_line('test_multi_newline'), 'test', 'single line with multi newlines';
system('echo -ne "test\n  \n  " > config/test_multi_space');
is get_config_line('test_multi_space'), 'test',   'single line with multi newlines and spaces';
system('echo -ne "test\ntest2" > config/test_multi');
throws_ok { get_config_line('test_multi') }         qr/more than one line/,
    'multi line';

chdir '/';  # work around warnings in File::Temp CLEANUP handler
