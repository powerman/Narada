#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Exception;
use DBI;
use Narada::Config qw( set_config );

chomp(my ($db, $login, $pass) = `cat t/.answers`);

if ($db eq q{}) {
    plan skip_all => 'No database provided for testing';
} else {
    plan tests => 9;
}

use File::Temp qw( tempdir );
chomp(my $cwd=`pwd`);
$ENV{PATH} = "$cwd/blib/script:$ENV{PATH}";
$ENV{PERL5LIB} = "$cwd/blib:$ENV{PERL5LIB}";
chdir tempdir( CLEANUP => 1 )
    and system('narada-new') == 0
    or die "Unable to create project: $!";

$::dbh = DBI->connect('dbi:mysql:', $login, $pass, {RaiseError=>1});
my $db_exists = $::dbh->prepare('SHOW DATABASES LIKE ?')->execute($db);
BAIL_OUT 'Database already exists' if 0 < $db_exists;
$::dbh->prepare('CREATE DATABASE '.$db)->execute();

#

is   scalar `narada-mysql param </dev/null 2>&1`, "Usage: narada-mysql\n", 'usage';
is   scalar `narada-mysql       </dev/null 2>&1`, "ERROR: config/db/db absent or empty!\n", 'no db';
set_config('db/db', $db);
set_config('db/login', 'wrong login');
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'bad login, empty pass';
set_config('db/pass', 'wrong pass');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Access denied/i, 'bad pass';
set_config('db/login', $login);
set_config('db/pass', $pass);
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'auth ok';
is   scalar `echo "SELECT 1+2;" | narada-mysql 2>&1`, "1+2\n3\n", 'simple select';
set_config('db/host', '127.0.0.172');
set_config('db/port', '3306');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Can't connect/i, 'bad host';
set_config('db/host', '127.0.0.1');
set_config('db/port', '3307');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Can't connect/i, 'bad port';
set_config('db/port', '3306');
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'good host:port';

###

$::dbh->prepare('DROP DATABASE '.$db)->execute();
chdir '/';  # work around warnings in File::Temp CLEANUP handler

