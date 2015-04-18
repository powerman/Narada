use warnings;
use strict;
use feature ':5.10';
use Test::More;
use Test::Exception;

use Narada::Config qw( get_config set_config );


my @res;
lives_ok { @res = get_config('var') }   'get_config do no throw';
is_deeply \@res, [undef],               'get_config return undef';
throws_ok { set_config('var', 'val') } qr/directory/ims, 'set_config throws';


done_testing();
