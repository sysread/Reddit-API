package Reddit::API::Thing;

use strict;
use warnings;
use Carp;
use List::Util qw/first/;

our @BOOL_FIELDS = qw/is_self likes clicked saved hidden over_18 over18/;


use fields qw/_session name id/;

sub new {
    my ($class, $reddit, $source_data) = @_;
    my $self = fields::new($class);
    $self->{_session} = $reddit;
    $self->load_from_source_data($source_data) if $source_data;
    return $self;
}

sub load_from_source_data {
    my ($self, $source_data) = @_;
    if ($source_data) {
        foreach my $field (keys %$source_data) {
            my $setter = sprintf 'set_%s', $field;
            if ($self->can($setter)) {
                $self->can($setter)->($self, $source_data->{$field});
            } elsif (first {$_ eq $field} @BOOL_FIELDS) {
                $self->set_bool($field, $source_data->{$field});
            } else {
	            eval { $self->{$field} = $source_data->{$field} };
	            warn sprintf("Field %s is missing from package %s\n", $field, ref $self)
	                if $@;
            }
        }
    }
}

sub set_bool {
    my ($self, $field, $value) = @_;
    $self->{$field} = $value ? 1 : 0;
}

1;