package Reddit::API::Link;

use strict;
use warnings;
use Carp;

require Reddit::API::VotableThing;
require Reddit::API::Comment;

use base   qw/Reddit::API::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports
              created_utc banned_by subreddit title author_flair_text is_self
              author media_embed author_flair_css_class selftext domain
              num_comments clicked saved thumbnail subreddit_id approved_by
              selftext_html created hidden over_18 permalink/;

# likes may be true, false, or null, based on user vote
sub set_likes {
    my ($self, $value) = @_;
    $self->set_bool('likes', $value) if defined $value;
}

sub comments {
    my $self = shift;
    return $self->{_session}->get_comments(permalink => $self->{permalink});
}

1;