use t::share; guard my $guard;

BEGIN {
use_ok( 'Narada::Config' );
}

diag( "Testing Narada::Config $Narada::Config::VERSION" );

done_testing();
