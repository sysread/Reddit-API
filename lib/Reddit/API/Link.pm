package Reddit::API::Link;

use Carp;

require Reddit::API::VotableThing;

use base   qw/Reddit::API::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports
              created_utc banned_by subreddit title author_flair_text is_self
              author media_embed author_flair_css_class selftext domain
              num_comments clicked saved thumbnail subreddit_id approved_by
              selftext_html created hidden over_18 permalink/;

sub comments {
    my $self = shift;
    return $self->{_session}->get_comments(permalink => $self->{permalink});
}

1;

__END__

=pod

=head1 NAME

Reddit::API::Link

=head1 DESCRIPTION

Wraps a posted link or "self-post".

=head1 SUBROUTINES/METHODS

=over

=item comments()

Wraps C<Reddit::API::get_comments>, implicitly providing the permalink parameter.

=back

=head1 INTERNAL ROUTINES

=over

=item set_likes

Conditionally sets the value of "likes" since it may validly be true, false, or
neither, in the case of no vote being cast.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
