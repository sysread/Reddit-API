package Reddit::API::SubReddit;

use strict;
use warnings;
use Carp;

require Reddit::API;
require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
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