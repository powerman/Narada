#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use File::Temp qw( tempdir );
    chomp(my $cwd=`pwd`); $ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
    chdir tempdir( CLEANUP => 1 )
        and system('narada-new') == 0
        or die "Unable to create project: $!";

    ok !-e 'var/log/current', 'log file not exists';
    system('runsv ./service/log/ &>/dev/null & sleep 1');
    ok -e 'var/log/current', 'log file exists';
}
use Narada::Log qw( $LOGSOCK );

ok ref $LOGSOCK, 'log object imported';

$LOGSOCK->level('INFO');
$LOGSOCK->DEBUG('debug');
$LOGSOCK->INFO('info');
ok 256 == system('grep debug var/log/current &>/dev/null'), 'log file not contain "debug"';
ok 0   == system('grep info  var/log/current &>/dev/null'), 'log file contain "info"';

system('sv x ./service/log/');

chdir '/';  # work around warnings in File::Temp CLEANUP handler
