package Reddit::Client;

our $VERSION = '0.93';
$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp;

use Data::Dumper   qw/Dumper/;
use JSON           qw//;
use File::Spec     qw//;
use Digest::MD5    qw/md5_hex/;
use POSIX          qw/strftime/;
use File::Path::Expand qw//;

require Reddit::Client::Account;
require Reddit::Client::Comment;
require Reddit::Client::Link;
require Reddit::Client::SubReddit;
require Reddit::Client::Request;

#===============================================================================
# Constants
#===============================================================================

use constant DEFAULT_LIMIT      => 25;

use constant VIEW_HOT           => '';
use constant VIEW_NEW           => 'new';
use constant VIEW_CONTROVERSIAL => 'controversial';
use constant VIEW_TOP           => 'top';
use constant VIEW_RISING	=> 'rising';
use constant VIEW_DEFAULT       => VIEW_HOT;

use constant VOTE_UP            => 1;
use constant VOTE_DOWN          => -1;
use constant VOTE_NONE          => 0;

use constant SUBMIT_LINK        => 'link';
use constant SUBMIT_SELF        => 'self';
use constant SUBMIT_MESSAGE     => 'message';

use constant API_ME             => 0;
use constant API_INFO           => 1;
use constant API_SEARCH         => 2;
use constant API_LOGIN          => 3;
use constant API_SUBMIT         => 4;
use constant API_COMMENT        => 5;
use constant API_VOTE           => 6;
use constant API_SAVE           => 7;
use constant API_UNSAVE         => 8;
use constant API_HIDE           => 9;
use constant API_UNHIDE         => 10;
use constant API_SUBREDDITS     => 11;
use constant API_LINKS_FRONT    => 12;
use constant API_LINKS_OTHER    => 13;
use constant API_DEL            => 14;
use constant API_MESSAGE        => 15;
use constant API_COMMENTS_FRONT	=> 16;
use constant API_COMMENTS	=> 17;

use constant SUBREDDITS_HOME    => '';
use constant SUBREDDITS_MINE    => 'mine';
use constant SUBREDDITS_POPULAR => 'popular';
use constant SUBREDDITS_NEW     => 'new';
use constant SUBREDDITS_CONTRIB => 'contributor';
use constant SUBREDDITS_MOD     => 'moderator';

#===============================================================================
# Parameters
#===============================================================================

our $DEBUG           = 0;
our $BASE_URL        = 'https://oauth.reddit.com';
our $LINK_URL        = 'https://www.reddit.com';
our $UA              = sprintf 'Reddit::Client/%f', $VERSION;

our @API;
$API[API_ME            ] = ['GET',  '/api/v1/me'     ];
$API[API_INFO          ] = ['GET',  '/api/info'      ];
#$API[API_INFO          ] = ['GET',  '/by_id/%s'      ];
$API[API_SEARCH        ] = ['GET',  '/reddits/search'];
$API[API_LOGIN         ] = ['POST', '/api/login/%s'  ];
$API[API_SUBMIT        ] = ['POST', '/api/submit'    ];
$API[API_COMMENT       ] = ['POST', '/api/comment'   ];
$API[API_VOTE          ] = ['POST', '/api/vote'      ];
$API[API_SAVE          ] = ['POST', '/api/save'      ];
$API[API_UNSAVE        ] = ['POST', '/api/unsave'    ];
$API[API_HIDE          ] = ['POST', '/api/hide'      ];
$API[API_UNHIDE        ] = ['POST', '/api/unhide'    ];
$API[API_SUBREDDITS    ] = ['GET',  '/reddits/%s'    ];
$API[API_LINKS_OTHER   ] = ['GET',  '/%s'            ];
$API[API_LINKS_FRONT   ] = ['GET',  '/r/%s/%s'       ];
$API[API_DEL           ] = ['POST', '/api/del'       ];
$API[API_MESSAGE       ] = ['POST', '/api/compose'   ];
$API[API_COMMENTS      ] = ['GET',  '/r/%s/comments' ];
$API[API_COMMENTS_FRONT] = ['GET',  '/comments'      ];
#===============================================================================
# Package routines
#===============================================================================

sub DEBUG {
    if ($DEBUG) {
        my ($format, @args) = @_;
        my $ts  = strftime "%Y-%m-%d %H:%M:%S", localtime;
        my $msg = sprintf $format, @args;
        chomp $msg;
        printf STDERR "[%s] [ %s ]\n", $ts, $msg;
    }
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
    	'modhash',      # store session modhash
    	'cookie',       # store user cookie
    	'session_file', # path to session file
    	'user_agent',   # user agent string
    	'token',	# oauth authorization token
    	'tokentype',    # unused but saved for reference
    	'last_token',	# time last token was acquired
    	'client_id',	# These 4 values saved for automatic token refreshing
    	'secret',
	'username',
	'password',
);

sub new {
    my ($class, %param) = @_;
    my $self = fields::new($class);

    if (not exists $param{user_agent}) {
        carp "Reddit::Client->new: user_agent required in future version.";
        $param{user_agent} = $UA;
    }
    $self->{user_agent} = $param{user_agent};

    #if ($param{session_file}) {
    #    $self->{session_file} = $param{session_file};
    #    $self->load_session;
    #}

	if ($param{username} || $param{password} || $param{client_id} || $param{secret}) {
		if (!$param{username} || !$param{password} || !$param{client_id} || !$param{secret}) {
			croak "If any of username, password, client_id, or secret are provided, all are required.";
		} else {
			$self->get_token(
					client_id	=> $param{client_id},
					secret		=> $param{secret},
					username	=> $param{username},
					password	=> $param{password},	
			);
		}
	}

    return $self;
}

#===============================================================================
# Internal management
#===============================================================================

sub request {
    my ($self, $method, $path, $query, $post_data) = @_;

	if (!$self->{last_token} || $self->{last_token} <= time - 3600) {
		$self->get_token(client_id=>$self->{client_id}, secret=>$self->{secret}, username=>$self->{username}, password=>$self->{password});
	}

    # Trim leading slashes off of the path
    $path =~ s/^\/+//;
    my $request = Reddit::Client::Request->new(
        user_agent => $self->{user_agent},
        url        => sprintf('%s/%s', $BASE_URL, $path),
        method     => $method,
        query      => $query,
        post_data  => $post_data,
        modhash    => $self->{modhash},
        cookie     => $self->{cookie},
	token	   => $self->{token},
	tokentype  => $self->{tokentype},
    );

    return $request->send;
}

sub get_token {
	my ($self, %param) = @_;
	$self->{client_id} 	= $param{client_id} || croak "need client_id"; 
	$self->{secret} 	= $param{secret}    || croak "need secret";
	$self->{username}	= $param{username}  || croak "need username";
	$self->{password}	= $param{password}  || croak "need password";
	$self->{last_token} 	= time;

	my $message = Reddit::Client::Request->token_request($self->{client_id}, $self->{secret}, $self->{username}, $self->{password}, $self->{user_agent});
	my $j = JSON::decode_json($message);
	$self->{token} 		= $j->{access_token};
	$self->{tokentype} 	= $j->{token_type};

	if (!$self->{token}) { croak "Unable to get or parse token."; }
}

# alias for get_token
sub authorize {
	my ($self, %rest) = @_;
	return $self->get_token(%rest);
}

sub json_request {
    my ($self, $method, $path, $query, $post_data) = @_;
    DEBUG('%4s JSON', $method);

    if ($method eq 'POST') {
        $post_data ||= {};
        $post_data->{api_type} = 'json';
    } else { 
        #$path .= '.json'; # the oauth api returns json by default
    }

    my $response = $self->request($method, $path, $query, $post_data);
    my $json     = JSON::from_json($response);
	#use Data::Dump::Color;
	#dd $json;

    if (ref $json eq 'HASH' && $json->{json}) {
        my $result = $json->{json};
        if (@{$result->{errors}}) {
            DEBUG('API Errors: %s', Dumper($result->{errors}));
            my @errors = map {
                sprintf '[%s] %s', $_->[0], $_->[1]
            } @{$result->{errors}};
            croak sprintf("Error(s): %s", join('|', @errors));
        } else {
            return $result;
        }
    } else {
        return $json;
    }
}

sub api_json_request {
    my ($self, %param) = @_;
    my $args     = $param{args} || [];
    my $api      = $param{api};
    my $data     = $param{data};
    my $callback = $param{callback};

    croak 'Expected "api"' unless defined $api;

    DEBUG('API call %d', $api);

    my $info   = $API[$api] || croak "Unknown API: $api";
    my ($method, $path) = @$info;
    $path = sprintf $path, @$args;

    my ($query, $post_data);
    if ($method eq 'GET') {
        $query = $data;
    } else {
        $post_data = $data;
    }

    my $result = $self->json_request($method, $path, $query, $post_data);
	#use Data::Dump::Color;
	#dd $result;

    if (exists $result->{errors}) {
        my @errors = @{$result->{errors}};

        if (@errors) {
            DEBUG("ERRORS: @errors");
            my $message = join(' | ', map { join(', ', @$_) } @errors);
            croak $message;
        }
    }
	#use Data::Dump::Color;
	#dd $result;

    if (defined $callback && ref $callback eq 'CODE') {
        return $callback->($result);
    } else {
        return $result;
    }
}

sub is_logged_in {
    return defined $_[0]->{modhash};
}

sub require_login {
    my $self = shift;
    return;
    croak 'You must be logged in to perform this action'
        unless $self->is_logged_in;
}

sub save_session {
    my ($self, $file) = @_;
    $self->require_login;
    $self->{session_file} || $file || croak 'Expected $file';

    # Prepare session and file path
    my $session   = { modhash => $self->{modhash}, cookie => $self->{cookie} };
    my $file_path = File::Path::Expand::expand_filename(
        defined $file ? $file : $self->{session_file}
    );

    DEBUG('Save session to %s', $file_path);

    # Write out session
    open(my $fh, '>', $file_path) or croak $!;
    print $fh JSON::to_json($session);
    close $fh;

    # If session file was updated, replace the field
    $self->{session_file} = $file_path;

    return 1;
}

sub load_session {
    my ($self, $file) = @_;
    $self->{session_file} || $file || croak 'Expected $file';
    my $file_path = File::Path::Expand::expand_filename(
        defined $file ? $file : $self->{session_file}
    );

    DEBUG('Load session from %s', $file_path);

    if (-f $file_path) {
        open(my $fh, '<', $file_path) or croak $!;
        my $data = do { local $/; <$fh> };
        close $fh;

        if ($data) {
            my $session = JSON::from_json($data);
            $self->{modhash} = $session->{modhash};
            $self->{cookie}  = $session->{cookie};

            DEBUG('Session loaded successfully');

            return 1;
        } else {
            return 0;
        }
    } else {
        DEBUG('Session file not found');
        return 0;
    }
}

#===============================================================================
# User and account management
#===============================================================================

sub authenticate {
	my ($self, $client_id, $client_secret) = @_;
}

sub login {
    my ($self, $usr, $pwd) = @_;
    !$usr && croak 'Username expected';
    !$pwd && croak 'Password expected';

    DEBUG('Log in user %s', $usr);

    my $result = $self->api_json_request(
        api      => API_LOGIN,
        args     => [$usr],
        data     => { user => $usr, passwd => $pwd },
    );

    $self->{modhash} = $result->{data}{modhash};
    $self->{cookie}  = $result->{data}{cookie};

    return 1;
}

sub me {
    my $self = shift;
    DEBUG('Request user account info');
    #$self->require_login;
    my $result = $self->api_json_request(api => API_ME);
    #return Reddit::Client::Account->new($self, $result->{data});
    return Reddit::Client::Account->new($self, $result);
}

sub list_subreddits {
    my ($self, $type) = @_;
    DEBUG('List subreddits [%s]', $type);
    defined $type || croak 'Expected $type"';

    $self->require_login
        if $type eq SUBREDDITS_MOD
        || $type eq SUBREDDITS_MINE
        || $type eq SUBREDDITS_CONTRIB;

    my $result = $self->api_json_request(api => API_SUBREDDITS, args => [$type]);
    return {
        map { $_->{data}{display_name} => Reddit::Client::SubReddit->new($self, $_->{data}) }
            @{$result->{data}{children}}
    };
}

sub mod_subreddits     { $_[0]->require_login; return $_[0]->list_subreddits(SUBREDDITS_MOD)     }
sub my_subreddits      { $_[0]->require_login; return $_[0]->list_subreddits(SUBREDDITS_MINE)    }
sub contrib_subreddits { $_[0]->require_login; return $_[0]->list_subreddits(SUBREDDITS_CONTRIB) }

sub home_subreddits    { return $_[0]->list_subreddits(SUBREDDITS_HOME)    }
sub popular_subreddits { return $_[0]->list_subreddits(SUBREDDITS_POPULAR) }
sub new_subreddits     { return $_[0]->list_subreddits(SUBREDDITS_NEW)     }

#===============================================================================
# Finding subreddits and listings
#===============================================================================

sub info {
    my ($self, $id) = @_;
    DEBUG('Get info for id %s', $id);
    defined $id || croak 'Expected $id';
    my $query->{id} = $id;
    
    my $info = $self->api_json_request(
	api => API_INFO, 
	args => [$id], 
	data=>$query);
    return $info->{data}->{children}[0]->{data};
}

# shortcut to get permalink from info() object
sub get_permalink {
	# the naming convention is inconsistent here; a comment "id" has no 
	# prefix, and its "name" is the id prefixed with "t1_". All other ids 
	# have a prefix.
	my ($self, $commentid, $link_id) = @_;
	my $info = $self->info($link_id);
	return sprintf "%s%s%s", $LINK_URL, $info->{permalink}, $commentid;
}

sub find_subreddits {
    my ($self, $query) = @_;
    defined $query || croak 'Expected $query';
    DEBUG('Search subreddits: %s', $query);
    my $result = $self->api_json_request(api => API_SEARCH, data => { q => $query });
    return {
        map { $_->{data}{display_name} => Reddit::Client::SubReddit->new($self, $_->{data}) }
            @{$result->{data}{children}}
    };
}

sub fetch_links {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $view      = $param{view}      || VIEW_DEFAULT;
    my $limit     = $param{limit}     || DEFAULT_LIMIT;
    my $before    = $param{before};
    my $after     = $param{after};

    DEBUG('Fetch %d link(s): %s/%s?before=%s&after=%s', $limit, $subreddit, $view, ($before || '-'), ($after || '-'));

    my $query  = {};
    if ($before || $after || $limit) { # limit is always defined
        $query->{limit}  = $limit  if defined $limit;
        $query->{before} = $before if defined $before;
        $query->{after}  = $after  if defined $after;
    }

    $subreddit = subreddit($subreddit);

    my $args = [$view];
    unshift @$args, $subreddit if $subreddit;

    my $result = $self->api_json_request(
        api      => ($subreddit ? API_LINKS_FRONT : API_LINKS_OTHER),
        args     => $args,
        data     => $query,
    );

    return {
        before => $result->{data}{before},
        after  => $result->{data}{after},
        items  => [ map {Reddit::Client::Link->new($self, $_->{data})} @{$result->{data}{children}} ],
    };
}

sub get_subreddit_comments {
	my ($self, %param) = @_;
	my $subreddit 	= $param{subreddit} 	|| '';
	my $view 	= $param{view} 		|| VIEW_DEFAULT;
        my $before    	= $param{before};
    	my $after     	= $param{after};

	my $query = {};
        $query->{before} = $before if defined $before;
        $query->{after}  = $after  if defined $after;
	# if limit exists but is false (for "no limit"), get as many as possible
	# this will probably be 100 but ask for a ridiculous amount anyway
	# if we don't provide a limit, Reddit will give us 25
	if (exists $param{limit}) {
		$query->{limit} = $param{limit} || 500;
	} else {
		$query->{limit} = 25;
	}

	$subreddit = subreddit($subreddit); # remove slashes and leading r/
    	my $args = [$view];
    	unshift @$args, $subreddit if $subreddit;

    	my $result = $self->api_json_request(
        	api      => ($subreddit ? API_COMMENTS : API_COMMENTS_FRONT),
        	args     => $args,
        	data     => $query,
    	);
	#use Data::Dump::Color;
	#dd $result;

    	return {
        	before => $result->{data}{before},
        	after  => $result->{data}{after},
        	items  => [ map {Reddit::Client::Comment->new($self, $_->{data})} @{$result->{data}{children}} ],
    	};
}

#===============================================================================
# Deleting stories or comments
#===============================================================================

# TODO unit test
sub delete_item {
    my ($self, %param) = @_;
    my $name = $param{name} || croak 'Expected "name"';
    $self->require_login;

    DEBUG('Delete post/comment %s', $name);

    my $result = $self->api_json_request(api => API_DEL, data => { id => $name });
    return 1;
}

#===============================================================================
# Submitting links
#===============================================================================

sub submit_link {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $title     = $param{title}     || croak 'Expected "title"';
    my $url       = $param{url}       || croak 'Expected "url"';
    $self->require_login;

    DEBUG('Submit link to %s: %s', $subreddit, $title, $url);

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title    => $title,
        url      => $url,
        sr       => $subreddit,
        kind     => SUBMIT_LINK,
    });

    return $result->{data}{name};
}

sub submit_text {
    my ($self, %param) = @_;
    my $subreddit = $param{subreddit} || '';
    my $title     = $param{title}     || croak 'Expected "title"';
    my $text      = $param{text}      || croak 'Expected "text"';
    $self->require_login;

    DEBUG('Submit text to %s: %s', $subreddit, $title);

    $subreddit = subreddit($subreddit);

    my $result = $self->api_json_request(api => API_SUBMIT, data => {
        title    => $title,
        text     => $text,
        sr       => $subreddit,
        kind     => SUBMIT_SELF,
    });

    return $result->{data}{name};
}

#===============================================================================
# Comments
#===============================================================================

sub get_comments { # currently broken
    my ($self, %param) = @_;
    my $permalink = $param{permalink} || croak 'Expected "permalink"';

    DEBUG('Retrieve comments for %s', $permalink);

    my $result   = $self->json_request('GET', $permalink);
    my $comments = $result->[1]{data}{children};
    return [ map { Reddit::Client::Comment->new($self, $_->{data}) } @$comments ];
}

sub submit_comment {
    my ($self, %param) = @_;
    my $parent_id = $param{parent_id} || croak 'Expected "parent_id"';
    my $comment   = $param{text}      || croak 'Expected "text"';

    DEBUG('Submit comment under %s', $parent_id);

    $self->require_login;
    my $result = $self->api_json_request(api => API_COMMENT, data => {
        thing_id => $parent_id,
        text     => $comment,
    });

    return $result->{data}{things}[0]{data}{id};
}

#===============================================================================
# Private messages
#===============================================================================

sub send_message {
    	my ($self, %param) = @_;
	my $to		= $param{to}	 	|| croak 'Expected "to"';
	my $subject	= $param{subject}	|| croak 'Expected "subject"';
	my $text	= $param{text}		|| croak 'Expected "text"';

	croak '"subject" cannot be longer than 100 characters' if length $subject > 100;
    	
	#$self->require_login;
    	DEBUG('Submit message to %s: %s', $to, $subject);

    	my $result = $self->api_json_request(api => API_MESSAGE, data => {
       	 to    		=> $to,
       	 subject  	=> $subject,
       	 text		=> $text,
       	 kind   	=> SUBMIT_MESSAGE,
    	});

	return $result;
}

#===============================================================================
# Voting
#===============================================================================

sub vote {
    my ($self, $name, $direction) = @_;
    defined $name      || croak 'Expected $name';
    defined $direction || croak 'Expected $direction';
    DEBUG('Vote %d for %s', $direction, $name);
    croak 'Invalid vote direction' unless "$direction" =~ /^(-1|0|1)$/;
    $self->require_login;
    $self->api_json_request(api => API_VOTE, data => { dir => $direction, id  => $name });
}

#===============================================================================
# Saving and hiding
#===============================================================================

sub save {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    DEBUG('Save %s', $name);
    $self->require_login;
    $self->api_json_request(api => API_SAVE, data => { id => $name });
}

sub unsave {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    DEBUG('Unsave %s', $name);
    $self->require_login;
    $self->api_json_request(api => API_UNSAVE, data => { id => $name });
}

sub hide {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    DEBUG('Hide %s', $name);
    $self->require_login;
    $self->api_json_request(api => API_HIDE, data => { id => $name });
}

sub unhide {
    my $self = shift;
    my $name = shift || croak 'Expected $name';
    DEBUG('Unhide %s', $name);
    $self->require_login;
    $self->api_json_request(api => API_UNHIDE, data => { id => $name });
}

1;

__END__

=pod

=head1 NAME

Reddit::Client - A perl wrapper for Reddit

=head1 SYNOPSIS

    use Reddit::Client;

    # You'll need these 4 pieces of information for every script:
    my $client_id  = "DFhtrhBgfhhRTd";
    my $secret     = "KrDNsbeffdbILOdgbgSvSBsbfFs";
    my $username   = "reddit-username";
    my $password   = "reddit-password";


    # Create a Reddit::Client object and authorize in one step
    my $reddit = new Reddit::Client(
	user_agent 	=> 'MyScriptName 0.5 by /u/earth-tone',
	client_id	=> $client_id,
	secret		=> $secret,
	username	=> $username,
	password	=> $password,
    );
	
    # Or create object then authenticate. Useful if you need to authenticate more than once, for example if you were to check the inboxes of several accounts
    my $reddit       = Reddit::Client->new(
        user_agent   => 'MyApp/1.0',
    );

    # Get oauth token. This replaces the "login" method.
    $reddit->authorize(
	client_id	=> $client_id,
	secret		=> $secret,
	username	=> $username,
	password	=> $password,
    );


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

Reddit::Client provides methods and simple object wrappers for objects exposed
by the Reddit API. This module handles HTTP communication, oauth session management, and communication with Reddit's external API.

For more information about the Reddit API, see L<https://github.com/reddit/reddit/wiki/API>.

=head1 CONSTANTS

    VIEW_HOT            "Hot" links feed
    VIEW_NEW            "New" links feed
    VIEW_RISING		"Rising" links feed
    VIEW_CONTROVERSIAL  "Controversial" links feed
    VIEW_TOP            "Top" links feed

    VIEW_DEFAULT        Default feed if not specified (VIEW_HOT)
    DEFAULT_LIMIT       The default number of links to be retried (25)

    VOTE_UP             Up vote
    VOTE_DOWN           Down vote
    VOTE_NONE           Remove any vote

    SUBREDDITS_HOME     List reddits on the homepage
    SUBREDDITS_POPULAR  List popular reddits
    SUBREDDITS_NEW      List new reddits
    SUBREDDITS_MINE     List reddits for which the logged in user is subscribed
    SUBREDDITS_CONTRIB  List reddits for which the logged in user is a contributor
    SUBREDDITS_MOD      List reddits for which the logged in user is a moderator

=head1 GLOBALS

=over


=item $DEBUG

When set to true, outputs a small amount of debugging information.


=back

=head1 SUBROUTINES/METHODS

=over

=item new(user_agent => , [client_id =>, secret =>, username=>, password =>])

Begins a new reddit session. 
If C<session_file> is provided, it will be read and parsed as JSON. If
session data is found, it is restored. Otherwise, a new session is started.
Session data does not restore the user_agent string of the original session.

=item authenticated

Returns true if there is an oauth token.


=item save_session($path)

Saves the current session to C<$path>. Throws an error if the user is not logged
in. C<$path> is only required if the Reddit::Client instance was created without
the C<session_file> parameter.


=item load_session($path)

Attempts to load the session from C<$path>. When successful, returns true and
stores the session file path for future use.


=item login($usr, $pwd)

Attempts to log the user in. Throws an error on failure.


=item me

Returns a Reddit::Client::Account object.


=item list_subreddits($type)

Returns a list of Reddit::Client::SubReddit objects for C<$type>, where C<$type>
is a C<SUBREDDITS_*> constant.


=item my_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_MINE)>. 


=item home_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_HOME)>. 


=item mod_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_MOD)>. 


=item contrib_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_CONTRIB)>.


=item popular_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_POPULAR)>.


=item new_subreddits

Syntactic sugar for C<list_subreddits(SUBREDDITS_NEW)>.


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


=item delete_item(name => ...)

Deletes a post or comment. The object's full name is required.


=item submit_link(subreddit => ..., title => ..., url => ...)

Submits a link to a reddit. Returns the id of the new link.


=item submit_text(subreddit => ..., title => ..., text => ...)

Submits a self-post to a reddit. Returns the id of the new post.

=item get_subreddit_comments([subreddit => ...][before => ...][after => ...][limit => ...])

Return a list of Reddit::Client::Comment objects from a subreddit or multi. All arguments are optional. If subreddit is ommitted, a multi of the subscribed subreddits from the authenticating account will be returned (i.e. what you see when you visit reddit.com's from page and are logged in). If limit is ommitted, Reddit's default limit of 25 is used. If limit is present but false, this is interpreted as no limit and the maximum is returned (100).

=item get_comments($permalink)

Disabled in the current version (0.93).

Returns a list ref of Reddit::Client::Comment objects underneath the
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

=head1 INTERNAL ROUTINES

=over

=item DEBUG

When C<$Reddit::Client::DEBUG> is true, acts as syntactic sugar for
warn(sprintf(@_)). Used to provided logging.


=item require_login

Throws an error if the user is not logged in. No longer used.


=item subreddit

Strips slashes and leading /r from a subreddit to ensure that only
the "display name" of the subreddit is returned.


=item request

Performs a request to reddit's servers using LWP. If the user is
logged in, adds the "uh" and "modhash" parameters to POST queries
as well as adding the reddit-specified cookie value for reddit_session.


=item json_request

Wraps C<request>, configuring the parameters to perform the request
with an api_type of "json". After the request is complete, parses the
JSON result and throws and error if one is specified in the result
contents. Otherwise, returns the json data portion of the result.


=item api_json_request

Wraps C<json_request>, getting method and path from an API_CONSTANT.


=back

=head1 AUTHOR

<mailto:earth-tone@ubwg.net>

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
