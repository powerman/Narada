use t::share; guard my $guard;
use DBI;

use Narada::Config qw( set_config );

my ($db, $login, $pass) = path(wd().'/t/.answers')->lines_utf8({ chomp => 1 });

if ($db eq q{}) {
    plan skip_all => 'No database provided for testing';
}


$::dbh = DBI->connect('dbi:mysql:', $login, $pass, {RaiseError=>1});
my $db_exists = $::dbh->prepare('SHOW DATABASES LIKE ?')->execute($db);
BAIL_OUT 'Database already exists' if 0 < $db_exists;
$::dbh->prepare('CREATE DATABASE '.$db)->execute();

#

is   scalar `narada-mysql param </dev/null 2>&1`, "Usage: narada-mysql\n", 'usage';
is   scalar `narada-mysql       </dev/null 2>&1`, "ERROR: config/mysql/db absent or empty!\n", 'no db';
set_config('mysql/db', $db);
set_config('mysql/login', 'wrong login');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Access denied|\A\z/i, 'bad login, empty pass';
set_config('mysql/pass', 'wrong pass');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Access denied/i, 'bad pass';
set_config('mysql/login', $login);
set_config('mysql/pass', $pass);
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'auth ok';
is   scalar `echo "SELECT 1+2;" | narada-mysql 2>&1`, "1+2\n3\n", 'simple select';
set_config('mysql/host', '127.0.0.1');
set_config('mysql/port', '36');
like scalar `narada-mysql       </dev/null 2>&1`, qr/Can't connect/i, 'bad port';
set_config('mysql/port', '3306');
is   scalar `narada-mysql       </dev/null 2>&1`, q{}, 'good host:port';

###

$::dbh->prepare('DROP DATABASE '.$db)->execute();
done_testing();

