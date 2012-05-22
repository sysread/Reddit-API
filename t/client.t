use strict;
use warnings;
use Carp;
use JSON qw//;
use Reddit::Client;
use Test::MockModule;
use Test::More tests => 35;

sub json_request_mock {
    my $data = shift || {};
    my $r    = HTTP::Response->new(200);
    $r->content(JSON::to_json({ json => { data => $data, errors => [] }}));
    return sub { $r };
}

sub json_error_mock {
    my $data = shift || [];
    my $r    = HTTP::Response->new(200);
    $r->content(JSON::to_json({ json => { errors => $data } }));
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

{ ## list_subreddits
    my $reddit = Reddit::Client->new();
    $lwp->mock('request', json_request_mock({ children => [{ data => { display_name => 'test' }}]}));

    eval { $reddit->list_subreddits() };
    ok($@ =~ /^Expected \$type/, 'list_subreddits');

    eval { $reddit->list_subreddits(Reddit::Client::SUBREDDITS_MOD) };
    ok($@ =~ /^You must be logged in to perform this action/, 'list_subreddits');

    eval { $reddit->list_subreddits(Reddit::Client::SUBREDDITS_MINE) };
    ok($@ =~ /^You must be logged in to perform this action/, 'list_subreddits');

    eval { $reddit->list_subreddits(Reddit::Client::SUBREDDITS_CONTRIB) };
    ok($@ =~ /^You must be logged in to perform this action/, 'list_subreddits');

    my $result = $reddit->list_subreddits(Reddit::Client::SUBREDDITS_HOME);
    ok(keys(%$result) == 1, 'list_subreddits');
    ok(exists $result->{test}, 'list_subreddits');
    ok($result->{test}->isa('Reddit::Client::SubReddit'), 'list_subreddits');

    $lwp->unmock_all;
}

{ ## info -- TODO
    ok(1, 'info');
}

{ ## find_subreddits
    my $reddit = Reddit::Client->new();
    $lwp->mock('request', json_request_mock({ children => [{ data => { display_name => 'test' }}]}));

    eval { $reddit->find_subreddits };
    ok($@ =~ /^Expected \$query/, 'find_subreddits');

    my $result = $reddit->find_subreddits('test');
    ok(keys(%$result) == 1, 'find_subreddits');
    ok(exists $result->{test}, 'find_subreddits');
    ok($result->{test}->isa('Reddit::Client::SubReddit'), 'find_subreddits');

    $lwp->unmock_all;
}

{ ## fetch_links
    my $reddit = Reddit::Client->new();
    $lwp->mock('request', json_request_mock({ before => 'before', after => 'after', children => [ { data => {} }]}));

    my $links = $reddit->fetch_links();
    ok($links->{before} eq 'before', 'fetch_links');
    ok($links->{after}  eq 'after',  'fetch_links');
    ok($links->{items}[0]->isa('Reddit::Client::Link'), 'fetch_links');

    $lwp->unmock_all;
}

{ ## submit link
    my $reddit = Reddit::Client->new();
    $reddit->{modhash} = 'test';
    $reddit->{cookie}  = 'test';
    $lwp->mock('request', json_request_mock({ name => 'test' }));

    eval { $reddit->submit_link };
    ok($@ =~ /^Expected "title"/, 'submit_link');

    eval { $reddit->submit_link(title => 'foo') };
    ok($@ =~ /^Expected "url"/, 'submit_link');

    ok($reddit->submit_text(title => 'foo', text => 'bar') eq 'test', 'submit_link');

    $lwp->unmock_all;
}

{ ## submit_text
    my $reddit = Reddit::Client->new();
    $reddit->{modhash} = 'test';
    $reddit->{cookie}  = 'test';
    $lwp->mock('request', json_request_mock({ name => 'test' }));

    eval { $reddit->submit_text };
    ok($@ =~ /^Expected "title"/, 'submit_text');

    eval { $reddit->submit_text(title => 'foo') };
    ok($@ =~ /^Expected "text"/, 'submit_text');

    ok($reddit->submit_text(title => 'foo', text => 'bar') eq 'test', 'submit_text');

    $lwp->unmock_all;
}

{ ## get_comments
    ok(1, 'get_comments');
}

{ ## submit_comment
    my $reddit = Reddit::Client->new();
    $reddit->{modhash} = 'test';
    $reddit->{cookie}  = 'test';
    $lwp->mock('request', json_request_mock({ things => [ { data => { id => 'foo' }}]}));
    
    eval { $reddit->submit_comment };
    ok($@ =~ /^Expected "parent_id"/, 'submit_comment');
    
    eval { $reddit->submit_comment(parent_id => 'test') };
    ok($@ =~ /^Expected "text"/, 'submit_comment');
    
    ok($reddit->submit_comment(parent_id => 'test', text => 'test') eq 'foo', 'submit_comment');
    $lwp->unmock_all;
}

{ ## vote
    ok(1, 'vote');
}

{ ## save
    ok(1, 'save');
}

{ ## unsave
    ok(1, 'unsave');
}

{ ## hide
    ok(1, 'hide');
}

{ ## unhide
    ok(1, 'unhide');
}

1;