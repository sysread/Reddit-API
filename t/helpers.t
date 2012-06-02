use strict;
use warnings;
use Carp;
use JSON       qw//;
use File::Temp qw/tempfile/;
use IO::Capture::Stderr;
use Reddit::Client;
use Test::More tests => 18;

my ($fh, $filename) = tempfile();
my $reddit = Reddit::Client->new(session_file => $filename);

## DEBUG
{
    local $Reddit::Client::DEBUG = 0;

    my $capture = IO::Capture::Stderr->new({ FORCE_CAPTURE_WARN => 1 });
    $capture->start;

    Reddit::Client::DEBUG('test');

    $capture->stop;
    ok(!$capture->read, 'DEBUG');
}

{
    local $Reddit::Client::DEBUG = 1;

    my $capture = IO::Capture::Stderr->new({ FORCE_CAPTURE_WARN => 1 });
    $capture->start();

    Reddit::Client::DEBUG('test 1');
    Reddit::Client::DEBUG("test 2\n");
    Reddit::Client::DEBUG("test %d", 3);

    $capture->stop;
    my @lines = $capture->read;

    ok(@lines == 3, 'DEBUG');
    like($lines[0] ,qr/^\[... ...\s+\d{1,2} \d\d:\d\d:\d\d \d\d\d\d\] \[ test 1 \]\n$/, 'DEBUG');
    like($lines[1] ,qr/^\[... ...\s+\d{1,2} \d\d:\d\d:\d\d \d\d\d\d\] \[ test 2 \]\n$/, 'DEBUG');
    like($lines[2] ,qr/^\[... ...\s+\d{1,2} \d\d:\d\d:\d\d \d\d\d\d\] \[ test 3 \]\n$/, 'DEBUG');
}


## subreddit
ok(Reddit::Client::subreddit('/r/foo')  eq 'foo', 'subreddit');
ok(Reddit::Client::subreddit('/foo')    eq 'foo', 'subreddit');
ok(Reddit::Client::subreddit('/r/foo/') eq 'foo', 'subreddit');
ok(Reddit::Client::subreddit('/')       eq '',    'subreddit');
ok(!defined Reddit::Client::subreddit('foo/bar'), 'subreddit');


## require_login
eval{ $reddit->require_login };
ok($@, 'require_login');


## is_logged_in
ok(!$reddit->is_logged_in, 'is_logged_in');
$reddit->{modhash} = '.', $reddit->{cookie} = '.';
ok($reddit->is_logged_in, 'is_logged_in');


## save_session
ok($reddit->save_session, 'save_session');
my $session_data = do { local $/; <$fh> };
my $session = JSON::from_json($session_data);
ok($session->{modhash} eq '.', 'save_session');
ok($session->{cookie}  eq '.', 'save_session');


## load_session
$reddit->{modhash} = undef, $reddit->{cookie} = '';
$reddit->load_session;
ok($session->{modhash} eq '.', 'load_session');
ok($session->{cookie}  eq '.', 'load_session');

1;