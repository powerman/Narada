#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 6;
use Test::Exception;

BEGIN {
    use File::Temp qw( tempdir );
    chomp(my $cwd=`pwd`); $ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
    chdir tempdir( CLEANUP => 1 )
        and system('narada-new') == 0
        or die "Unable to create project: $!";

    system('echo file > config/log/type');
    system('echo var/log/file > config/log/output');
    ok !-e 'var/log/file', 'log file not exists';
}
use Narada::Log qw( $LOGFILE );

ok -e 'var/log/file', 'log file exists';
ok ref $LOGFILE, 'log object imported';
ok !-s 'var/log/file', 'log file empty';

$LOGFILE->level('INFO');
$LOGFILE->DEBUG('debug');
system('true'); # force FH flush in perl
ok !-s 'var/log/file', 'log file still empty after DEBUG()';

$LOGFILE->INFO('info');
system('true'); # force FH flush in perl
ok -s 'var/log/file', 'log file not empty after INFO()';

chdir '/';  # work around warnings in File::Temp CLEANUP handler
