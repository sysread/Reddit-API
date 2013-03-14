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
    join '&', map {uri_encode($_) . '=' . uri_encode($param->{$_})} sort keys %$param;
}

sub build_request {
    my $self    = shift;
    my $request = HTTP::Request->new();

    $request->uri($self->{url});
    $request->header('Cookie', sprintf('reddit_session=%s', $self->{cookie}))
        if $self->{cookie};

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
    
    return $request;
}

sub send {
    my $self    = shift;
    my $request = $self->build_request;

    Reddit::Client::DEBUG('%4s request to %s', $self->{method}, $self->{url});

    my $ua  = LWP::UserAgent->new(agent => $self->{user_agent}, env_proxy => 1);
    my $res = $ua->request($request);

    if ($res->is_success) {
        return $res->content;
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
