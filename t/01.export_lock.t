use warnings;
use strict;
use Test::More;

use Narada::Lock qw( :ALL );

my @exports
    = qw( shared_lock exclusive_lock unlock_new unlock child_inherit_lock )
    ;
my @not_exports
    = qw( )
    ;

plan +(@exports + @not_exports)
    ? ( tests       => @exports + @not_exports                  )
    : ( skip_all    => q{This module doesn't export anything}   )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( ! __PACKAGE__->can($not_export) );
}
