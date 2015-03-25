package Reddit::Client::Account;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/has_mail created modhash created_utc link_karma
              comment_karma is_gold is_mod has_mod_mail over_18/;

1;

__END__

=pod

=head1 NAME

Reddit::Client::Account

=head1 DESCRIPTION

Stores information about the logged in user account.

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
