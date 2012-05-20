use strict;
use warnings;
use Carp;
use JSON qw//;
use Reddit::API;
use Reddit::API::Thing;
use Reddit::API::VotableThing;
use Reddit::API::Comment;
use Test::More tests => 13;

my $reddit = Reddit::API->new();

## set_bool
my $thing = Reddit::API::Thing->new();

$thing->set_bool('name', JSON::true);
ok($thing->{name} == 1, 'set_bool');

$thing->set_bool('name', JSON::false);
ok($thing->{name} == 0, 'set_bool');

## load_from_source_data
my $account = Reddit::API::Account->new();
my $warns = '';
open my $warns_fh, '>', \$warns;

{
    local *STDERR = $warns_fh;
    $account->load_from_source_data({ name => 'foo', id => 'bar', invalid => 'baz', has_mail => JSON::false });
}

close $warns_fh;

ok($account->{name} eq 'foo',   'load_from_source_data');
ok($account->{id}   eq 'bar',   'load_from_source_data');
ok($account->{has_mail} == 0,   'load_from_source_data');
ok(!exists $account->{invalid}, 'load_from_source_data');
ok($warns =~ "^Field invalid is missing from package Reddit::API::Account\n", 'load_from_source_data');

## set_likes
my $votable = Reddit::API::VotableThing->new();

$votable->load_from_source_data({ likes => JSON::null });
ok(!defined $votable->{likes}, 'set_likes');

$votable->load_from_source_data({ likes => JSON::true });
ok($votable->{likes} == 1, 'set_likes');

$votable->load_from_source_data({ likes => JSON::false });
ok($votable->{likes} == 0, 'set_likes');

## set_replies
my $comment = Reddit::API::Comment->new($reddit);
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
ok($comment->{replies}[0]->isa('Reddit::API::Comment'), 'set_replies');

$comment->set_replies();
ok(scalar(@{$comment->{replies}}) == 0, 'set_replies');

1;