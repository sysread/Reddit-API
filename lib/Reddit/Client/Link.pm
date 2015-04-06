package Reddit::Client::Link;

use strict;
use warnings;
use Carp;

require Reddit::Client::VotableThing;

use base   qw/Reddit::Client::VotableThing/;
use fields qw/link_flair_text media url link_flair_css_class num_reports
              created_utc banned_by subreddit title author_flair_text is_self
              author media_embed author_flair_css_class selftext domain
              num_comments clicked saved thumbnail subreddit_id approved_by
              selftext_html created hidden over_18 permalink/;

sub comments {
    my $self = shift;
    return $self->{session}->get_comments(permalink => $self->{permalink});
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Link

=head1 DESCRIPTION

Wraps a posted link or "self-post".

=head1 SUBROUTINES/METHODS

=over

=item comments()

Wraps C<Reddit::Client::get_comments>, implicitly providing the permalink parameter.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
