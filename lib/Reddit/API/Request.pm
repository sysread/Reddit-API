package Reddit::API::Request;

use Carp;
use LWP::UserAgent qw//;
use HTTP::Request  qw//;
use URI::Encode    qw/uri_encode/;

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
        $self->{url} = sprintf('%s?%s', $self->{url}, $self->build_query($self->{query}))
    }

    if (defined $self->{post_data}) {
        ref $self->{post_data} eq 'HASH' || croak 'Expected HASH ref for "post_data"';
    }

    $self->{method} = $param{method} || 'GET';
    $self->{method} = uc $self->{method};

    return $self;
}

sub build_query {
    my ($self, $param) = @_;
    join '&', map {uri_encode($_) . '=' . uri_encode($param->{$_})} keys %$param;
}

sub send {
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
        $request->content($self->build_query($post_data));
    } else {
        $request->method('GET');
    }

    Reddit::API::DEBUG('%4s request to %s', $self->{method}, $self->{url});

    my $ua  = LWP::UserAgent->new(agent => $self->{user_agent}, env_proxy => 1);
    my $res = $ua->request($request);

    if ($res->is_success) {
        return $res->content;
    } else {
        croak sprintf('Request error: %s', $res->status_line);
    }
}

1;