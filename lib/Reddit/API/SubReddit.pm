package Reddit::API::SubReddit;

use strict;
use warnings;
use Carp;

require Reddit::API;
require Reddit::API::Link;
require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/over18 header_img created_utc header_title header_size
              description display_name created url title subscribers/;

sub links {
    my ($self, %param) = @_;
    my $view      = $param{view}      || Reddit::API::VIEW_DEFAULT();
    my $limit     = $param{limit}     || Reddit::API::DEFAULT_LIMIT();
    my $before    = $param{before};
    my $after     = $param{after};

    my @args = ('GET', $self->{url}. $view);
    if ($before || $after || $limit) {
	    my %query;
	    $query{limit}  = $limit  if defined $limit;
	    $query{before} = $before if defined $before;
	    $query{after}  = $after  if defined $after;
	    push @args, \%query;
    }

    my $result = $self->{_session}->json_request(@args);
    return {
        before => $result->{data}{before},
        after  => $result->{data}{after},
        items  => [ map {Reddit::API::Link->new($self->{_session}, $_->{data})} @{$result->{data}{children}} ],
    };
}

1;