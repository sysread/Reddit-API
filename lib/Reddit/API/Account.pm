package Reddit::API::Account;

use strict;
use warnings;
use Carp;

require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/has_mail created modhash created_utc link_karma
              comment_karma is_gold is_mod has_mod_mail/;

1;

__END__

=pod

=head1 NAME

Reddit::API::Account

=head1 DESCRIPTION

Stores information about the logged in user account.

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
