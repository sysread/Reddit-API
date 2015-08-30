package Reddit::Client::Request;

use strict;
use warnings;
use Carp;

use LWP::UserAgent qw//;
use HTTP::Request  qw//;
use URI::Encode    qw/uri_encode/;

require Reddit::Client;

use fields (
    'user_agent',
    'method',
    'url',
    'query',
    'post_data',
    'cookie',
    'modhash',
    'token',
    'tokentype'
);

sub new {
    my ($class, %param) = @_;
    my $self = fields::new($class);
    $self->{user_agent} = $param{user_agent} || croak 'Expected "user_agent"';
    $self->{url}        = $param{url}        || croak 'Expected "url"';
    $self->{query}      = $param{query};
    $self->{post_data}  = $param{post_data};
    $self->{cookie}     = $param{cookie};
    $self->{modhash}    = $param{modhash};
    $self->{token}	= $param{token};
    $self->{tokentype}	= $param{tokentype};

    if (defined $self->{query}) {
        ref $self->{query} eq 'HASH' || croak 'Expected HASH ref for "query"';
        $self->{url} = sprintf('%s?%s', $self->{url}, build_query($self->{query}))
    }

    if (defined $self->{post_data}) {
        ref $self->{post_data} eq 'HASH' || croak 'Expected HASH ref for "post_data"';
    }

    $self->{method} = $param{method} || 'GET';
    $self->{method} = uc $self->{method};

    return $self;
}

sub build_query {
    my $param = shift or return '';
    my $opt   = { encode_reserved => 1 };
    join '&', map {uri_encode($_, $opt) . '=' . uri_encode($param->{$_}, $opt)} sort keys %$param;
}

sub build_request {
    my $self    = shift;
    my $request = HTTP::Request->new();

    $request->uri($self->{url});
    #$request->header('Cookie', sprintf('reddit_session=%s', $self->{cookie}))
    #    if $self->{cookie};
    $request->header("Authorization"=> "$self->{tokentype} $self->{token}") if $self->{tokentype} && $self->{token};

    if ($self->{method} eq 'POST') {
        my $post_data = $self->{post_data} || {};
        $post_data->{modhash} = $self->{modhash} if $self->{modhash};
        $post_data->{uh}      = $self->{modhash} if $self->{modhash};

        $request->method('POST');
        $request->content_type('application/x-www-form-urlencoded');
        $request->content(build_query($post_data));
    } else {
        $request->method('GET');
    }

	#use Data::Dump::Color;
	#dd $request;
    return $request;
}

sub send {
    my $self    = shift;
    my $request = $self->build_request;

    Reddit::Client::DEBUG('%4s request to %s', $self->{method}, $self->{url});

    my $ua  = LWP::UserAgent->new(agent => $self->{user_agent}, env_proxy => 1);
    my $res = $ua->request($request);

    if ($res->is_success) {
	#use Data::Dump::Color;
	#dd $res->content;
        return $res->content;
    } else {
        croak sprintf('Request error: HTTP %s', $res->status_line);
    }
}

sub token_request {
	my ($self, $client_id, $secret, $username, $password, $useragent) = @_;

	my $url = "https://$client_id:$secret\@www.reddit.com/api/v1/access_token";

    	my $ua = LWP::UserAgent->new(user_agent => $useragent);
	my $req = HTTP::Request->new(POST => $url);
	$req->header('content-type' => 'application/x-www-form-urlencoded');

	my $postdata = "grant_type=password&username=$username&password=$password";
	$req->content($postdata);

    	my $res = $ua->request($req);

    	if ($res->is_success) {
        	return $res->decoded_content;
    	} else {
        	croak sprintf('Request error: HTTP %s', $res->status_line);
    	}
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Request

=head1 DESCRIPTION

HTTP request driver for Reddit::Client. Uses LWP to perform GET and POST requests
to the reddit.com servers. This module is used internally by the Reddit::Client
and is not designed for external use.

=head1 SUBROUTINES/METHODS

=over

=item new(%params)

Creates a new Reddit::Request::API instance. Parameters:

    user_agent    User agent string
    url           Target URL
    query         Hash of query parameters
    post_data     Hash of POST parameters
    cookie        Reddit session cookie
    modhash       Reddit session modhash


=item build_query($query)

Builds a URI-escaped query string from a hash of query parameters. This is *not*
a method of the class, but a package routine.


=item build_request

Builds an HTTP::Request object for LWP::UserAgent.


=item send

Performs the HTTP request and returns the result. Croaks on HTTP error.


=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
