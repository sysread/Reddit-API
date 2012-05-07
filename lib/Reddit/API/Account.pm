package Reddit::API::Account;

use strict;
use warnings;
use Carp;

require Reddit::API::Thing;

use base   qw/Reddit::API::Thing/;
use fields qw/has_mail created modhash created_utc link_karma
              comment_karma is_gold is_mod has_mod_mail/;

sub set_has_mail {
    my ($self, $value) = @_;
    $self->set_bool('has_mail', $value);
}

sub set_has_mod_mail {
    my ($self, $value) = @_;
    $self->set_bool('has_mod_mail', $value);
}

sub set_is_gold {
    my ($self, $value) = @_;
    $self->set_bool('is_gold', $value);
}

sub is_mod {
    my ($self, $value) = @_;
    $self->set_bool('is_mod', $value);
}

1;

__END__

=pod

=head1 NAME

Reddit::API::Account

=head1 DESCRIPTION

Stores information about the logged in user account.

=head1 SUBROUTINES/METHODS

=over


=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
