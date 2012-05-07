package Reddit::API;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use File::Spec     qw//;
use LWP::UserAgent qw//;
use HTTP::Request  qw//;
use URI::Encode    qw/uri_encode/;
use JSON           qw//;

require Reddit::API::Account;
require Reddit::API::Link;
require Reddit::API::Comment;

#===============================================================================
# Constants
#===============================================================================

use constant DEFAULT_LIMIT      => 25;

use constant VIEW_HOT           => '/';
use constant VIEW_NEW           => '/new';
use constant VIEW_CONTROVERSIAL => '/controversial';
use constant VIEW_TOP           => '/top';
use constant VIEW_DEFAULT       => VIEW_HOT;

use constant VOTE_UP            => 1;
use constant VOTE_DOWN          => -1;
use constant VOTE_NONE          => 0;

#===============================================================================
# Parameters
#===============================================================================

our $BASE_URL = 'http://www.reddit.com';
our $UA       = 'Reddit::API/0.1';

#===============================================================================
# Package routines
#===============================================================================

sub build_query {
    my $param = shift;
    join '&', map {uri_encode($_) . '=' . uri_encode($param->{$_})} keys %$param;
}

sub subreddit {
    my $subject = shift;
    $subject =~ s/^\/r//; # trim leading /r
    $subject =~ s/^\///;  # trim leading slashes
    $subject =~ s/\/$//;  # trim trailing slashes

    if ($subject !~ /\//) {   # no slashes in name - it's probably good
        if ($subject eq '') { # front page
            return '';
        } else {              # subreddit
	        return $subject;
        }
    } else { # fail
        return;
    }
}

#===============================================================================
# Class methods
#===============================================================================

use fields (
    'modhash', # store session modhash
    'cookie',  # store user cookie
);

sub new {
    my ($class, %param) = @_;
    my $session = $param{from_session_file};
    my $self    = fields::new($class);
    $self->load_session($session) if $session;
    return $self;
}

#===============================================================================
# Internal management
#===============================================================================

sub request {
    my ($self, $method, $path, $query, $post_data) = @_;
    $method = uc $method;
    $path   =~ s/^\///; # trim off leading slash

    my $request = HTTP::Request->new();
    my $url     = sprintf('%s/%s', $BASE_URL, $path);

    $url = sprintf('%s?%s', $url, build_query($query))
        if defined $query;

    $request->header('Cookie', sprintf('reddit_session=%s', $self->{cookie}))
        if $self->{cookie};

    if ($method eq 'POST') {
        $post_data = {} unless defined $post_data;
        $post_data->{modhash} = $self->{modhash} if $self->{modhash};
        $post_data->{uh}      = $self->{modhash} if $self->{modhash};

        $request->uri($url);
        $request->method('POST');
        $request->content_type('application/x-www-form-urlencoded');
        $request->content(build_query($post_data));
    } else {
        $request->uri($url);
        $request->method('GET');
    }

    my $ua  = LWP::UserAgent->new(agent => $UA, env_proxy => 1);
    my $res = $ua->request($request);

    if ($res->is_success) {
        return $res->content;
    } else {
        croak sprintf('Request error: %s', $res->status_line);
    }
}

sub json_request {
    my ($self, $method, $path, $query, $post_data) = @_;
    $query     ||= {};
    $post_data ||= {};

    $post_data->{api_type} = 'json';
    $path .= '.json' if $method eq 'GET';

    my $response = $self->request($method, $path, $query, $post_data);
    my $json = JSON::from_json($response);

    if (ref $json eq 'HASH' && $json->{json}) {
        my $result = $json->{json};
        if (@{$result->{errors}}) {
            my @errors = map {$_->[1]} @{$result->{errors}};
            croak sprintf("Error(s): %s", join('|', @errors));
        } else {
            return $result;
        }
    } else {
        return $json;
    }
}

sub is_logged_in {
    return defined $_[0]->{modhash};
}

sub require_login {
    my $self = shift;
    croak 'You must be logged in to perform this action'
        unless $self->is_logged_in;
}

sub save_session {
    my ($self, $file) = @_;
    $self->require_login;
    my $session = { modhash => $self->{modhash}, cookie => $self->{cookie} };
    my $file_path = File::Spec->catfile($file);
    open(my $fh, '>', $file_path) or croak $!;
    print $fh JSON::to_json($session);
    close $fh;
    return 1;
}

sub load_session {
    my ($self, $file) = @_;
    my $file_path = File::Spec->catfile($file);
    if (-f $file_path) {
        open(my $fh, '<', $file_path) or croak $!;
        my $data = do { local $/; <$fh> };
        close $fh;

        my $session = JSON::from_json($data);
        $self->{modhash} = $session->{modhash};
        $self->{cookie} = $session->{cookie};

        return 1;
    } else {
        return 0;
    }
}

#===============================================================================
# User and account management
#===============================================================================

sub login {
    my ($self, $usr, $pwd) = @_;
    !$usr && croak 'Username expected';
    !$pwd && croak 'Password expected';

    my $result = $self->json_request('POST', sprintf('/api/login/%s/', $usr), undef, { user => $usr, passwd => $pwd });
    my @errors = @{$result->{errors}};

    if (@errors) {
        my $message = join(' | ', map { join(', ', @$_) } @errors);
        croak sprintf('Login errors: %s', $message);
    } else {
        $self->{modhash} = $result->{data}{modhash};
        $self->{cookie}  = $result->{data}{cookie};
    }
}

sub me {
    my $self = shift;
    $self->require_login;
    if ($self->is_logged_in) {
	    my $result = $self->json_request('GET', '/api/me/');
	    return Reddit::API::Account->new($self, $result->{data});
    }
}

sub mine {
    my $self = shift;
    $self->require_login;
    if ($self->is_logged_in) {
        my $result = $self->json_request('GET', '/reddits/mine/');
        return {
            map {
                $_->{data}{display_name} => Reddit::API::SubReddit->new($self, $_->{data})
            } @{$result->{data}{children}}
        };
    }
}

#===============================================================================
# Finding subreddits and listings
#===============================================================================

sub info {
    my ($self, $id) = @_;
    defined $id || croak 'Expected $id';
    my $path   = sprintf '/by_id/%s.json', $id;
    my $result = $self->json_request('GET', $path);
    return $result;
}

sub find_subreddits {
    my ($self, $query) = @_;
    my $result = $self->json_request('GET', '/reddits/search/', { q => $query });
    my %subreddits = map {
        $_->{data}{display_name} => Reddit::API::SubReddit->new($self, $_->{data})
    } @{$result->{data}{children}};
    return \%subreddits;
}

sub fetch_links {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $view      = $param{view}      || Reddit::API::VIEW_DEFAULT();
    my $limit     = $param{limit}     || Reddit::API::DEFAULT_LIMIT();
    my $before    = $param{before};
    my $after     = $param{after};

    # Get subreddit and path
    $subreddit = subreddit($subreddit);
    my $path = $subreddit
        ? sprintf('/r/%s/%s', $subreddit, $view)
        : sprintf('/%s', $view);

    my @args = ('GET', $path);
    if ($before || $after || $limit) {
	    my %query;
	    $query{limit}  = $limit  if defined $limit;
	    $query{before} = $before if defined $before;
	    $query{after}  = $after  if defined $after;
	    push @args, \%query;
    }

    my $result = $self->json_request(@args);
    return {
        before => $result->{data}{before},
        after  => $result->{data}{after},
        items  => [ map {Reddit::API::Link->new($self, $_->{data})} @{$result->{data}{children}} ],
    };
}

#===============================================================================
# Submitting links
#===============================================================================

sub submit_link {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $title     = $param{title}     || croak 'Expected "title"';
    my $url       = $param{url}       || croak 'Expected "url"';

    $subreddit = subreddit($subreddit);
    $self->require_login;

    my $result = $self->json_request('POST', '/api/submit/', undef, {
        title => $title,
        url   => $url,
        sr    => $subreddit,
        kind  => 'link',
    });

    return $result->{data}{name};
}

sub submit_text {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $title     = $param{title}     || croak 'Expected "title"';
    my $text      = $param{text}      || croak 'Expected "text"';

    $subreddit = subreddit($subreddit);
    $self->require_login;

    my $result = $self->json_request('POST', '/api/submit/', undef, {
        title => $title,
        text  => $text,
        sr    => $subreddit,
        kind  => 'self',
    });

    return $result->{data}{name};
}

#===============================================================================
# Comments
#===============================================================================

sub get_comments {
    my ($self, %param) = @_;
    my $permalink = $param{permalink} || croak 'Expected "permalink"';
    my $result    = $self->{_session}->json_request('GET', $permalink);
    my $comments  = $result->[1]{data}{children};
    return [ map { Reddit::API::Comment->new($self, $_->{data}) } @$comments ];
}

sub submit_comment {
    my ($self, %param) = @_;
    my $parent_id = $param{parent_id} || croak 'Expected "parent_id"';
    my $comment   = $param{text}      || croak 'Expected "text"';

    $self->require_login;
    my $result = $self->json_request('POST', '/api/comment/', undef, {
        thing_id => $parent_id,
        text     => $comment,
    });

    my $id = $result->{data}{things}[0]{data}{id};
    return $id;
}

#===============================================================================
# Voting
#===============================================================================

sub vote {
    my ($self, $name, $direction) = @_;
    defined $name      || croak 'Expected $name';
    defined $direction || croak 'Expected $direction';
    croak 'Invalid vote direction' unless "$direction" =~ /^(-1|0|1)$/;
    $self->require_login;
    $self->json_request('POST', '/api/vote/', undef, { dir => $direction, id  => $name });
}

#===============================================================================
# Saving and hiding
#===============================================================================

sub save {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    $self->require_login;
    $self->json_request('POST', '/api/save/', undef, { id => $name });
}

sub unsave {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    $self->require_login;
    $self->json_request('POST', '/api/unsave/', undef, { id => $name });
}

sub hide {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    $self->require_login;
    $self->json_request('POST', '/api/hide/', undef, { id => $name });
}

sub unhide {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    $self->require_login;
    $self->json_request('POST', '/api/unhide/', undef, { id => $name });
}

1;

__END__

=pod

=head1 NAME

Reddit::API - A perl wrapper for Reddit

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Reddit::API;

    my $session_file = '~/.reddit';
    my $reddit       = Reddit::API->new(from_session_file => $session_file);

    unless ($reddit->is_logged_in) {
        $reddit->login('someone', 'secret');
        $reddit->save_session($session_file);
    }

    $reddit->submit_link(
        subreddit => 'perl',
        title     => 'Perl is still alive!',
        url       => 'http://www.perl.org'
    );

    my $links = $reddit->fetch_links(subreddit => '/r/perl', limit => 10);
    foreach (@{$links->{items}}) {
        ...
    }

=head1 DESCRIPTION

Reddit::API provides methods and simple object wrappers for objects exposed
by the Reddit API. This module handles HTTP communication, basic session
management (e.g. storing an active login session), and communication with
Reddit's external API.

For more information about the Reddit API, see L<https://github.com/reddit/reddit/wiki/API>.

=head1 CONSTANTS

	DEFAULT_LIMIT       The default number of links to be retried (25)
	VIEW_HOT            "Hot" links feed
	VIEW_NEW            "New" links feed
	VIEW_CONTROVERSIAL  "Controversial" links feed
	VIEW_TOP            "Top" links feed
	VIEW_DEFAULT        Default feed if not specified (VIEW_HOT)
	VOTE_UP             Up vote
	VOTE_DOWN           Down vote
	VOTE_NONE           "Un" vote

=head1 SUBROUTINES/METHODS

=over

=item new(from_source_file => ...)

Begins a new or loads an existing reddit session. If C<from_source_file> is
provided, it will be read and parsed as JSON. If session data is found, it
is restored. Otherwise, a new session is started.


=item is_logged_in()

Returns true(ish) if there is an active login session. No attempt is made to
validate the current session against the server.


=item save_session($path)

Saves the current session to C<$path>. Throws an error if the user is not logged in.


=item load_session($path)

Attempts to load the session from C<$path>. Returns true if successful.


=item login($usr, $pwd)

Attempts to log the user in. Throws an error on failure.


=item me()

Returns a Reddit::API::Account object


=item mine()

Returns a list of Reddit::API::SubReddit objects represting the list of reddits
to which the user is subscribed.


=item info($item_id)

Returns a has of information about C<$item_id>, which must be a complete name
(e.g., t3_xxxxx).


=item find_subreddits($query)

Returns a list of SubReddit objects matching C<$query>.


=item fetch_links(subreddit => ..., view => ..., limit => ..., before => ..., after => ...)

Returns a list of links from a reddit page. If C<subreddit> is specified,
the list of links is returned from the desired subreddit. Otherwise, the
links will be from the front page. C<view> specifieds the feed (e.g.
C<VIEW_NEW> or C<VIEW_HOT>). C<limit> may be used to limit the number of
objects returned, and C<before> and C<after> denote the placeholders for
slicing the feed up, just as the reddit urls themselves do. Data is returned
as a hash with three keys, I<before>, I<after>, and I<items>.


=item submit_link(subreddit => ..., title => ..., url => ...)

Submits a link to a reddit. Returns the id of the new link.


=item submit_text(subreddit => ..., title => ..., text => ...)

Submits a self-post to a reddit. Returns the id of the new post.


=item get_comments($permalink)

Returns a list ref of Reddit::API::Comment objects underneath the
the specified URL C<$permalink>. Unfortunately, this is the only 
method available via the API. Comments may be more easily accessed
via the Link object, which implicitly provides the C<$permalink>
parameter.

    my $links = $reddit->fetch_links(...);
    foreach (@{$links->{items}}) {
        my $comments = $_->comments();
    }


=item submit_comment(parent_id => ..., text => ...)

Submits a new comment underneath C<parent_id>.


=item vote(item_id => ..., direction => ...)

Votes for C<item_id>. C<direction> is one of C<VOTE_UP>, C<VOTE_DOWN>,
or C<VOTE_NONE>.


=item save($item_id)

Saves C<$item_id> under the user's account.


=item unsave($item_id)

Unsaves C<$item_id> under the user's account.


=item hide($item_id)

Hides $<item_id>. Throws an error if the user does not have permission to hide
the item in question.


=item unhide($item_id)

Unhides $<item_id>. Throws an error if the user does not have permission to
unhide the item in question.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
