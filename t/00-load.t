#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Reddit::API' ) || print "Bail out!\n";
}

diag( "Testing Reddit::API $Reddit::API::VERSION, Perl $], $^X" );
