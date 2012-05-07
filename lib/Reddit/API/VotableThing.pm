package Reddit::API::VotableThing;

use strict;
use warnings;
use Carp;

require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/ups downs likes score/;

sub vote {
    my ($self, $direction) = @_;
    $self->vote($self->{name}, $direction);
}

sub comment {
    my ($self, $comment) = @_;
    $self->{_session}->submit_comment(parent_id => $self->{name}, text => $comment);
}

sub save {
    my $self = shift;
    $self->{_session}->save($self->{name});
}

sub unsave {
    my $self = shift;
    $self->{_session}->unsave($self->{name});
}

sub hide {
    my $self = shift;
    $self->{_session}->hide($self->{name});
}

sub unhide {
    my $self = shift;
    $self->{_session}->unhide($self->{name});
}

1;