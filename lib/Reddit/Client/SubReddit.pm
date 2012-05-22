package Reddit::Client::SubReddit;

use Carp;

require Reddit::Client;
require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/over18 header_img created_utc header_title header_size
              description display_name created url title subscribers/;

sub links {
    my ($self, %param) = @_;
    return $self->{_session}->fetch_links(subreddit => $self->{url}, %param);
}

sub submit_link {
    my ($self, $title, $url) = @_;
    $self->{_session}->submit_link(title => $title, url => $url, sr => $self->{title}, kind => 'link');
}

sub submit_text {
    my ($self, $title, $text) = @_;
    $self->{_session}->submit_text(title => $title, text => $text, sr => $self->{title}, kind => 'text');
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

BSD license

=cut
