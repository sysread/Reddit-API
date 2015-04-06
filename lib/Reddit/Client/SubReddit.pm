package Reddit::Client::SubReddit;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/over18 header_img created_utc header_title header_size
              description display_name created url title subscribers
              public_description/;

sub links {
    my ($self, %param) = @_;
    return $self->{session}->fetch_links(subreddit => $self->{url}, %param);
}

sub submit_link {
    my ($self, $title, $url) = @_;
    $self->{session}->submit_link(title => $title, url => $url, sr => $self->{title}, kind => 'link');
}

sub submit_text {
    my ($self, $title, $text) = @_;
    $self->{session}->submit_text(title => $title, text => $text, sr => $self->{title}, kind => 'text');
}

1;
__END__

=pod

=head1 NAME

Reddit::Client::SubReddit

=head1 DESCRIPTION

Provides convenience methods for interacting with SubReddits.

=head1 SUBROUTINES/METHODS

=over

=item links(...)

Wraps C<Reddit::Client::fetch_links>, providing the subreddit parameter implicitly.

=item submit_link($title, $url)

Wraps C<Reddit::Client::submit_link>, providing the subreddit parameter implicitly.

=item submit_text($title, $text)

Wraps C<Reddit::Client::submit_text>, providing the subreddit parameter implicitly.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
