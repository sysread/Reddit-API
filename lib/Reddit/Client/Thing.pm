package Reddit::Client::Thing;

use strict;
use warnings;
use Carp;

use List::Util qw/first/;

our @BOOL_FIELDS = qw/is_self likes clicked saved hidden over_18 over18
                      has_verified_email hide_from_robots is_friend
                      has_mail has_mod_mail is_mod is_gold/;


use fields qw/session name id/;

sub new {
    my ($class, $reddit, $source_data) = @_;
    my $self = fields::new($class);
    $self->{session} = $reddit;
    $self->load_from_source_data($source_data) if $source_data;
    return $self;
}

sub load_from_source_data {
    require Reddit::Client;
 
    my ($self, $source_data) = @_;
    if ($source_data) {
        foreach my $field (keys %$source_data) {
            # Set data fields
            my $setter = sprintf 'set_%s', $field;
            if ($self->can($setter)) {
                $self->can($setter)->($self, $source_data->{$field});
            } elsif (first {$_ eq $field} @BOOL_FIELDS) {
                $self->set_bool($field, $source_data->{$field});
            } else {
	            eval { $self->{$field} = $source_data->{$field} };
	            Reddit::Client::DEBUG("Field %s is missing from package %s\n", $field, ref $self)
	                if $@;
            }

            # Add getter for field
            my $getter = sub { $_[0]->{$field} };
            my $class  = ref $self;
            my $method = sprintf '%s::get_%s', $class, $field;

            unless ($self->can($method)) {
                no strict 'refs';
                *{$method} = \&$getter;
            }
        }
    }
}

sub set_bool {
    my ($self, $field, $value) = @_;
    $self->{$field} = $value ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

Reddit::Client::Thing

=head1 DESCRIPTION

A "Thing" is the base class of all Reddit objects. Do not blame the author
for this. This is specified by the API documentation. The author just
perpetuated it.

Generally, consumers of the Reddit::Client module do not instantiate these
objects directly. Things offer a bit of syntactic sugar around the data
returned by reddit's servers, such as the ability to comment directly on
a Link object.

=head1 SUBROUTINES/METHODS

=over

=item new($session, $data)

Creates a new Thing. C<$session> must be an instance of Reddit::Client.
C<$data>, when present, must be a hash reference of key/value pairs.

=back

=head1 INTERNAL ROUTINES

=over

=item set_bool($field, $value)

Sets a field to a boolean value of 1 or 0, rather than the JSON
module's boolean type.

=item load_from_source_data($data)

Populates an instances field with data directly from JSON data returned
by reddit's servers.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
