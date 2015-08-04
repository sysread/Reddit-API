package Reddit::Client::Comment;

use strict;
use warnings;
use Carp;

require Reddit::Client::VotableThing;

use base   qw/Reddit::Client::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports created_utc
			  banned_by subreddit title author_flair_text is_self author media_embed
			  permalink author_flair_css_class selftext domain num_comments clicked
			  saved thumbnail subreddit_id approved_by selftext_html created hidden
			  over_18 parent_id replies link_id body body_html/;

sub set_replies {
    my ($self, $value) = @_;
    if (ref $value && exists $value->{data}{children}) {
	    $self->{replies} = [ map { Reddit::Client::Comment->new($self->{session}, $_->{data}) } @{$value->{data}{children}} ];
    } else {
        $self->{replies} = [];
    }
}

sub replies {
    return shift->{replies};
}

sub reply {
    my $self = shift;
    return $self->SUPER::submit_comment(@_);
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Comment

=head1 DESCRIPTION

Wraps a posted comment.

=head1 SUBROUTINES/METHODS

=over

=item replies()

Returns a list ref of replies underneath this comment.

=item reply(...)

Syntactic sugar for C<Reddit::Client::submit_comment()>.

=back

=head1 INTERNAL ROUTINES

=over

=item set_replies

Wraps the list of children in Comment class instances and ensures that comments
with no replies return an empty array for C<replies>.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
