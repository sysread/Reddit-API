package Reddit::API::VotableThing;

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

__END__

=pod

=head1 NAME

Reddit::API::VotableThing

=head1 DESCRIPTION

A Thing object, such as a Comment or Link, that may be voted on,
commented against, hidden, or saved.

=head1 SUBROUTINES/METHODS

=over

=item vote($direction)

=item comment($text)

=item save()

=item unsave()

=item hide()

=item unhide()


=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
