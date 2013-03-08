use strict;
use warnings;
use Carp;
use IO::Capture::Stderr;
use JSON qw//;
use Reddit::Client;
use Reddit::Client::Thing;
use Reddit::Client::VotableThing;
use Reddit::Client::Comment;
use Test::More tests => 13;

my $reddit = Reddit::Client->new();

## set_bool
my $thing = Reddit::Client::Thing->new();

$thing->set_bool('name', JSON::true);
ok($thing->{name} == 1, 'set_bool');

$thing->set_bool('name', JSON::false);
ok($thing->{name} == 0, 'set_bool');

## load_from_source_data
my $account = Reddit::Client::Account->new();
my $capture = IO::Capture::Stderr->new({ FORCE_CAPTURE_WARN => 1 });

{
    local $Reddit::Client::DEBUG = 1;

    $capture->start;

    $account->load_from_source_data({
        name     => 'foo',
        id       => 'bar',
        invalid  => 'baz',
        has_mail => JSON::false,
    });

    $capture->stop;
}

my $output = join "\n", $capture->read;
ok($account->{name} eq 'foo',   'load_from_source_data (1)');
ok($account->{id}   eq 'bar',   'load_from_source_data (2)');
ok($account->{has_mail} == 0,   'load_from_source_data (3)');
ok(!exists $account->{invalid}, 'load_from_source_data (4)');
ok($output =~ /Field invalid is missing from package Reddit::Client::Account/, 'load_from_source_data (5)');

## set_likes
my $votable = Reddit::Client::VotableThing->new();

$votable->load_from_source_data({ likes => JSON::null });
ok(!defined $votable->{likes}, 'set_likes');

$votable->load_from_source_data({ likes => JSON::true });
ok($votable->{likes} == 1, 'set_likes');

$votable->load_from_source_data({ likes => JSON::false });
ok($votable->{likes} == 0, 'set_likes');

## set_replies
my $comment = Reddit::Client::Comment->new($reddit);
$comment->set_replies({
    data => {
        children => [
            { data => {} },
            { data => {} },
            { data => {} },
        ]
    }
});

ok(scalar(@{$comment->{replies}}) == 3, 'set_replies');
ok($comment->{replies}[0]->isa('Reddit::Client::Comment'), 'set_replies');

$comment->set_replies();
ok(scalar(@{$comment->{replies}}) == 0, 'set_replies');

1;