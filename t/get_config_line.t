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

Echo('config/empty', "\n");
is get_config_line('empty'), q{}, 'empty with \n';
Echo('config/empty-n', q{});
is get_config_line('empty-n'), q{}, 'empty without \n';
Echo('config/test', "test\n");
is get_config_line('test'), 'test', 'single line with \n';
Echo('config/test-n', "test");
is get_config_line('test-n'), 'test', 'single line without \n';
Echo('config/test_multi_newline', "test\n  \n  \n");
is get_config_line('test_multi_newline'), 'test', 'single line with multi newlines';
Echo('config/test_multi_space', "test\n  \n  ");
is get_config_line('test_multi_space'), 'test',   'single line with multi newlines and spaces';
Echo('config/test_multi', "test\ntest2");
throws_ok { get_config_line('test_multi') }         qr/more than one line/,
    'multi line';

chdir '/';  # work around warnings in File::Temp CLEANUP handler


sub Echo {
    my ($file, $data) = @_;
    open my $fh, '>', $file or die "open: $!";
    print {$fh} $data;
    close $fh or die "close: $!";
    return;
}
