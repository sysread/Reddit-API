use strict;
use warnings;
use Carp;
use JSON qw//;
use Reddit::Client;
use Test::MockModule;
use Test::More qw/no_plan/;

sub json_request_mock {
    my $data = shift || {};
    my $json = JSON::to_json({ json => { data => $data, errors => [] }});
    my $r    = HTTP::Response->new(200);
    $r->content($json);
    return sub { $r };
}

sub json_error_mock {
    my $r = HTTP::Response->new(200);
    $r->content(JSON::to_json({ json => { errors => shift } }));
    return sub { $r };
}

my $lwp = Test::MockModule->new('LWP::UserAgent');

{ ## login
    my $reddit = Reddit::Client->new();

    eval { $reddit->login };
    ok($@ =~ /^Username expected/, 'login');

    eval { $reddit->login('test') };
    ok($@ =~ /^Password expected/, 'login');

    $lwp->mock('request', json_request_mock({ modhash => 'test', cookie  => 'test' }));

    $reddit->login('testuser', 'testpass');
    ok($reddit->{modhash} eq 'test', 'login');
    ok($reddit->{cookie}  eq 'test', 'login');

    $lwp->unmock_all;
}

{ ## me
    $lwp->mock('request', json_request_mock);

    my $reddit = Reddit::Client->new();
    $reddit->{modhash} = 'test';
    $reddit->{cookie}  = 'test';
    my $me = $reddit->me;
    ok($me->isa('Reddit::Client::Account'), 'me');

    $lwp->unmock_all;
}

1;