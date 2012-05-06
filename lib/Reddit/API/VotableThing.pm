package Reddit::API::VotableThing;

use strict;
use warnings;
use Carp;

require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/ups downs likes score/;

sub vote {
    my ($self, $direction) = @_;
    croak 'Invalid vote direction' unless "$direction" =~ /^(-1|0|1)$/;
    my $result = $self->{_session}->json_request('POST', '/api/vote/', undef, {
        uh  => $self->{_session}{modhash},
        dir => $direction,
        id  => $self->{name},
    });
}

1;