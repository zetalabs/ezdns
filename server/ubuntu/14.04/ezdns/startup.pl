use lib qw(/etc/ezdns/perl);

# enable if the mod_perl 1.0 compatibility is needed
# use Apache2::compat ( );

# preload all mp2 modules
# use ModPerl::MethodLookup;
# ModPerl::MethodLookup::preload_all_modules( );

use ModPerl::Util ( );

use Apache2::RequestRec ( );
use Apache2::RequestIO ( );
use Apache2::RequestUtil ( );

use Apache2::ServerRec ( );
use Apache2::ServerUtil ( );
use Apache2::Connection ( );

use Apache2::ServerRec ( );
use Apache2::ServerUtil ( );
use Apache2::Connection ( );
use Apache2::Log ( );
use Apache2::Access ( );

use APR::Table ( );

use ModPerl::Registry ( );

use Apache2::Const -compile => ':common';
use APR::Const -compile => ':common';

1;
