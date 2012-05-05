use warnings;
use strict;
use Carp;

use Data::Dumper;
use Reddit::API;

my $session = '/Users/jober/.reddit';
my $reddit  = Reddit::API->new();

unless ($reddit->load_session($session)) {
	$reddit->login('jsober', 'mrclean');
	$reddit->save_session($session)
	   or croak 'Unable to save session';
}

exit 0;