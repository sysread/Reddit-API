use strict;
use warnings;
use Carp;
use Test::MockObject;
use Test::More qw/no_plan/;

use Reddit::API::Request;

## Build query
ok(Reddit::API::Request::build_query() eq '', 'build_query');
ok(Reddit::API::Request::build_query({}) eq '', 'build_query');
ok(Reddit::API::Request::build_query({ foo => 'bar' }) eq 'foo=bar', 'build_query');
ok(Reddit::API::Request::build_query({ foo => 'bar', baz => 'bat' }) eq 'baz=bat&foo=bar', 'build_query');

## new
my $rq = Reddit::API::Request->new(
    user_agent => 'test',
    url        => 'http://www.example.com',
    query      => { foo => 'bar' },
    post_data  => { baz => 'bat' },
    cookie     => 'test',
    modhash    => 'test',
    method     => 'get',
);

ok($rq->{url} eq 'http://www.example.com?foo=bar', 'new');
ok($rq->{method} eq 'GET');

eval { Reddit::API::Request->new() };
ok($@ =~ /^Expected "user_agent"/, 'new');

eval { Reddit::API::Request->new(user_agent => 'foo') };
ok($@ =~ /^Expected "url"/, 'new');

## send


1;