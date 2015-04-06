package Reddit::Client::Account;

use strict;
use warnings;
use Carp;

require Reddit::Client::Thing;

use base   qw/Reddit::Client::Thing/;
use fields qw/has_mail created modhash created_utc link_karma
              gold_creddits inbox_count gold_expiration
              is_friend hide_from_robots has_verified_email
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

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
