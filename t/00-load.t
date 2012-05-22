#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Reddit::Client' ) || print "Bail out!\n";
}

diag( "Testing Reddit::Client $Reddit::Client::VERSION, Perl $], $^X" );
