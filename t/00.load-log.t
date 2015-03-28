use t::share; guard my $guard;

BEGIN {
use_ok( 'Narada::Log' );
}

diag( "Testing Narada::Log $Narada::Log::VERSION" );

done_testing();
