package Reddit::API::Comment;

use strict;
use warnings;
use Carp;

require Reddit::API::VotableThing;

use base   qw/Reddit::API::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports created_utc
			  banned_by subreddit title author_flair_text is_self author media_embed
			  permalink author_flair_css_class selftext domain num_comments clicked
			  saved thumbnail subreddit_id approved_by selftext_html created hidden
			  over_18 parent_id replies link_id body body_html/;

# likes may be true, false, or null, based on user vote
sub set_likes {
    my ($self, $value) = @_;
    $self->set_bool('likes', $value) if defined $value;
}

sub set_replies {
    my ($self, $value) = @_;
    if (ref $value && exists $value->{data}{children}) {
	    $self->{replies} = [ map { Reddit::API::Comment->new($self->{_session}, $_->{data}) } @{$value->{data}{children}} ];
    } else {
        $self->{replies} = [];
    }
}

1;