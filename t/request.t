use strict;
use warnings;
use Carp;
use HTTP::Response;
use Test::MockModule;
use Test::More tests => 15;

use Reddit::Client::Request;

my $rq = Reddit::Client::Request->new(
    user_agent => 'test',
    url        => 'http://www.example.com',
    query      => { foo => 'bar' },
    post_data  => { baz => 'bat' },
    cookie     => 'test',
    modhash    => 'test',
    method     => 'post',
);

## Build query
{
    ok(Reddit::Client::Request::build_query() eq '', 'build_query');
    ok(Reddit::Client::Request::build_query({}) eq '', 'build_query');
    ok(Reddit::Client::Request::build_query({ foo => 'bar' }) eq 'foo=bar', 'build_query');
    ok(Reddit::Client::Request::build_query({ foo => 'bar', baz => 'bat' }) eq 'baz=bat&foo=bar', 'build_query');
}

## new
{
    ok($rq->{url} eq 'http://www.example.com?foo=bar', 'new');
    ok($rq->{method} eq 'POST', 'new');
    
    eval { Reddit::Client::Request->new() };
    ok($@ =~ /^Expected "user_agent"/, 'new');
    
    eval { Reddit::Client::Request->new(user_agent => 'foo') };
    ok($@ =~ /^Expected "url"/, 'new');
}

## build_request
{
    my $request = $rq->build_request;
    ok($request->method eq 'POST', 'build_request');
    ok($request->uri eq 'http://www.example.com?foo=bar', 'build_request');
    ok($request->content eq 'baz=bat&modhash=test&uh=test', 'build_request');
    #ok($request->header('Cookie') eq 'reddit_session=test', 'build_request');
    ok($request->content_type eq 'application/x-www-form-urlencoded', 'build_request');
}

## send
{
    my $lwp = Test::MockModule->new('LWP::UserAgent');
    $lwp->mock('request', sub { my $r = HTTP::Response->new(200); $r->content('test response'); $r; });
    
    my $result = $rq->send;
    ok(defined $result && $result eq 'test response', 'send');
    
    $lwp->mock('request', sub { HTTP::Response->new(500, 'test error') });
    eval { $rq->send };
    ok($@, 'send');
    ok($@ =~ /^Request error: HTTP 500 test error/, 'send');
    
    $lwp->unmock_all;
}

1;
