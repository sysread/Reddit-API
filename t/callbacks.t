use strict;
use warnings;
use Carp;
use Test::More qw/no_plan/;
use Reddit::API;

{ ## callback_login
    my $reddit = Reddit::API->new();
    eval { $reddit->callback_login({ errors => [], data => { modhash => '...', cookie => '...' } }) };
    ok(!$@, 'callback_login');
    ok($reddit->{modhash}, 'callback_login');
    ok($reddit->{cookie},  'callback_login');
}

{ ## callback_me
    my $reddit = Reddit::API->new();
    my $me = eval { $reddit->callback_me({ data => {} }) };
    ok(!$@, 'callback_me');
    ok($me->isa('Reddit::API::Account'), 'callback_me');
}

{ ## callback_info
    my $reddit = Reddit::API->new();
    my $result = {};
    $result->{data} = {};
    $result->{data}{children} = [ { data => { display_name => 'test' } }];
    my $subreddits = eval { $reddit->callback_list_subreddits($result) };
    ok(!$@, 'callback_list_subreddits');
    ok($subreddits->{test}->isa('Reddit::API::SubReddit'), 'callback_list_subreddits');
}

{ ## callback_fetch_links
    my $reddit = Reddit::API->new();
    my $result = { data => { before => 'before', after => 'after', children => [ { data => {} } ] } };
    my $links = $reddit->callback_fetch_links($result);
    ok(!$@, 'callback_fetch_links');
    ok($links->{before} eq 'before', 'callback_fetch_links');
    ok($links->{after}  eq 'after',  'callback_fetch_links');
    ok($links->{items}[0]->isa('Reddit::API::Link'), 'callback_fetch_links');
}

{ ## callback_submit
    my $reddit = Reddit::API->new();
    my $result = { data => { name => 'foo' } };
    my $link   = $reddit->callback_submit($result);
    ok(!$@, 'callback_submit');
    ok($link eq 'foo', 'callback_submit');
}

1;