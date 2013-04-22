#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Exception;

plan skip_all => 'OS Inferno not installed' if !grep {-x "$_/emu-g" && /inferno/} split /:/, $ENV{PATH};
plan tests => 6;

use File::Temp qw( tempdir );
chomp(my $cwd=`pwd`);
$ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
$ENV{PERL5LIB} ||= q{};
$ENV{PERL5LIB} = "$cwd/blib:$ENV{PERL5LIB}";
chdir tempdir( CLEANUP => 1 )
    and system('narada-new') == 0
    or die "Unable to create project: $!";

# get rid of nasty "Killed" message from bash
$ENV{PATH} = "./tmp:$ENV{PATH}";
chomp(my $orig = `which emu-g`);
open my $f, '>', 'tmp/emu-g'                or die "open: $!";
printf {$f} "%s\n", '#!/bin/bash';
printf {$f} "%s\n", '[ -r /dev/stdin ] && stdin=/dev/stdin || stdin=/dev/null';
printf {$f} "%s %s\n", $orig, '"$@" <$stdin &';
printf {$f} "%s\n", 'wait 2>/dev/null';
close $f                                    or die "close: $!";
chmod 0755, 'tmp/emu-g'                     or die "chmod: $!";

is scalar `narada-emu a b                   2>&1`, "sh: a: './a' file does not exist\n";
is scalar `echo shutdown -h | narada-emu    2>&1`, "shutdown -h\n; ";
is scalar `narada-emu "echo hello inferno"  2>&1`, "hello inferno\n";
is scalar `narada-emu "os -d . pwd"         2>&1`, scalar `pwd`;
is scalar `narada-emu -c0 "cat /dev/jit"    2>&1`, '0';
is scalar `narada-emu -c1 "cat /dev/jit"    2>&1`, '1';

chdir '/';  # work around warnings in File::Temp CLEANUP handler
