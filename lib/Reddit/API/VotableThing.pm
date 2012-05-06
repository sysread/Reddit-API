package Reddit::API::VotableThing;

use strict;
use warnings;
use Carp;

require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/ups downs likes score/;

sub vote {
    my ($self, $direction) = @_;
    $self->{_session}->require_login;
    croak 'Invalid vote direction' unless "$direction" =~ /^(-1|0|1)$/;
    $self->{_session}->json_request('POST', '/api/vote/', undef, {
        dir => $direction,
        id  => $self->{name},
    });
}

sub save {
    my $self = shift;
    $self->{_session}->require_login;
    $self->{_session}->json_request('POST', '/api/save/', undef, {
        id => $self->{name},
    });
}

sub unsave {
    my $self = shift;
    $self->{_session}->require_login;
    $self->{_session}->json_request('POST', '/api/unsave/', undef, {
        id => $self->{name},
    });
}

sub comment {
    my ($self, $comment) = @_;
    $self->{_session}->require_login;
    my $result = $self->{_session}->json_request('POST', '/api/comment/', undef, {
        thing_id => $self->{name},
        text     => $comment,
    });
    
    return $result->{data}{things}[0]{data}{id};
}

1;