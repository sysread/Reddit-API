package Reddit::Client::ApiCall;

=head1 NAME

Reddit::Client::ApiCall

=head1 SYNOPSIS

    my $request = Reddit::Client::ApiCall->new(
        appid    => 'my-app-name,
        appver   => $My::App::Name::VERSION,
        author   => 'my_reddit_username',
        modhash  => $modhash_from_saved_session,
        cookie   => $cookie_from_saved_session,
        method   => 'GET',
        api_path => '/r/%s/%s',
        api_args => ['perl', 'top'],
        params   => {
            limit  => 20,
            after  => $previd,
            before => $nextid,
        }
    );

    my $result = $request->send;

=head1 DESCRIPTION

This is the basic API request class type. It makes and sends the request,
returning the decoded JSON response as a hash ref.

=cut

use Moo;
use Types::Standard qw(-types);
use Carp;
use HTTP::Request;
use JSON::XS qw(decode_json);
use URI::Encode qw(uri_encode);
require Reddit::Client;

=head1 ATTRIBUTES

=head2 appid = Str

An identifier for the application using this library. See HTTP user agent rules
at https://github.com/reddit/reddit/wiki/API. Defaults to 'Reddit-Client'. Note
that using the default may cause an application to be rate-limited by Reddit's
servers.

=cut

has appid => (
    is => 'ro',
    isa => Str,
    default => sub { 'Reddit-Client' },
);

=head2 appver = Num

A numerical version for the application using this library. Defaults to
C<$Reddit::Client::VERSION>.

=cut

has appver => (
    is => 'ro',
    isa => Num,
    default => sub {
        no warnings 'once';
        $Reddit::Client::VERSION;
    },
);

=head2 author = Str

The application author's username. Defaults to 'anonymous'.

=cut

has author => (
    is => 'ro',
    isa => Str,
    default => 'anonymous',
);

=head2 modhash => Maybe[Str]

If authenticated, this should be set to the session modhash.

=cut

has modhash => (
    is => 'ro',
    isa => Maybe[Str],
    predicate => 'has_modhash',
);

=head2 cookie = Maybe[Str]

If authenticated, thsi should be set to the session cookie.

=cut

has cookie => (
    is => 'ro',
    isa => Maybe[Str],
    predicate => 'has_cookie',
);

=head2 agent_string = Str

By default, the user agent string is automatically generated from the 'appid',
'appver', and 'author' attributes. This attribute may be overridden to use a
string that doesn't conform to the documented guidelines.

=cut

has agent_string => (
    is => 'lazy',
    isa => Str,
);

sub _build_agent_string {
    my $self   = shift;
    my $appid  = $self->appid;
    my $appver = $self->appver;
    my $author = $self->author;
    return sprintf 'perl:%s:v%0.2f (by /u/%s)', $appid, $appver, $author;
}

=head2 method = Enum[GET POST]

The HTTP method to be used for this API call.

=cut

has method => (
    is => 'ro',
    isa => Enum[qw(GET POST)],
    default => sub { 'GET' },
);

=head2 api_path = Str

The API path. If there are parameters, such as a username or thing id, this
value may be specified as an sprintf format string. See 'api_args'.

=cut

has api_path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=head2 api_args = Maybe[ArrayRef[Defined]]

Specifies any format parameters to pass to the 'api_path' format string.

=cut

has api_args => (
    is => 'ro',
    isa => Maybe[ArrayRef[Defined]],
    default => sub { [] },
);

=head2 params = HashRef

A hash ref of parameters required for the API call.

=cut

has params => (
    is => 'ro',
    isa => HashRef,
    default => sub { },
);

=head1 READ ONLY ATTRIBUTES

=head2 url = Str

An automatically constructed url string.

=cut

has url => (
    is => 'lazy',
    isa => Str,
    init_arg => undef,
);

sub _build_url {
    no warnings 'once';

    my $self = shift;
    my $base = $Reddit::Client::BASE_URL;
    my $path = sprintf $self->api_path, @{$self->api_args};

    my $query = '';
    if ($self->is_get) {
        $query = '?' . build_query($self->params);
    }

    return sprintf '%s/%s.json%s', $base, $path, $query;
}

=head2 post_data = Maybe[Str]

The POST body content for the request (for POST requests).

=cut

has post_data => (
    is => 'lazy',
    isa => Maybe[Str],
    init_arg => undef,
);

sub _build_post_data {
    my $self = shift;

    if ($self->is_post) {
        my $params = {
            ($self->has_modhash ? (uh => $self->modhash) : ()),
            api_type => 'json',
            %{$self->params},
        };

        return build_query($params)
    }

    return;
}

=head2 request = InstanceOf[HTTP::Request]

The L<HTTP::Request> object used to make the request.

=cut

has request => (
    is => 'lazy',
    isa => InstanceOf['HTTP::Request'],
    init_arg => undef,
);

sub _build_request {
    my $self = shift;
    my $request = HTTP::Request->new();

    # Build POST data
    if ($self->is_post) {
        $request->method('POST');
        $request->content_type('application/x-www-form-urlencoded');
        $request->content($self->post_data);
    }

    # Add cookie if user is authenticated
    $request->header('Cookie', sprintf('reddit_session=%s', $self->cookie))
        if $self->has_cookie;

    return $request;
}

=head2 ua = InstanceOf[LWP::UserAgent]

The L<LWP::UserAgent> used to make the request.

=cut

has ua => (
    is => 'lazy',
    isa => InstanceOf['LWP::UserAgent'],
);

sub _build_ua {
    my $self = shift;
    return LWP::UserAgent->new(agent => $self->agent_string, env_proxy => 1);
}

=head1 METHODS

=head2 send

Makes the HTTP request to Reddit's servers and returns the results as a hash
ref. Croaks on error.

=cut

sub send {
    my $self = shift;
    my $response = $self->ua->request($self->request);

    if ($response->is_success) {
        my $json = decode_json($response->content);
        my $result = $json->{json};

        if (@{$result->{errors}}) {
            my @errors = map { sprintf '[%s] %s', $_->[0], $_->[1] } @{$result->{errors}};
            croak sprintf "Error(s): %s", join('|', @errors);
        }
        else {
            return $result;
        }

    }

    croak sprintf 'HTTP Error %d: %s', $response->code, $response->status_line;
}

=head1 INTERNAL METHODS

=head2 is_post

Returns true if this is a POST request.

=cut

sub is_post { $_[0]->method eq 'POST' }

=head2 is_get

Returns true if this is a GET request.

=cut

sub is_get { $_[0]->method eq 'GET' }

=head2 build_query

Generates a URI-encoded string from the key-value pairs in a hash ref.

=cut

sub build_query {
    my $param = shift or return '';
    my $opt   = { encode_reserved => 1 };
    join '&', map {uri_encode($_, $opt) . '=' . uri_encode($param->{$_}, $opt)} keys %$param;
}

1;
