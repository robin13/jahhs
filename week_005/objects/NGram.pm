package NGram;
# the role NGram should be defined in some pod like:
# is equivalent to ($obj->can 'getSize' and $obj->can 'getNth')

sub new {
  my($package) = shift;
  my $self = {'size' => scalar @_
	      ,'fields' => [@_]
	     };
  return bless($self,$package);
}

sub getSize{
  my $self = shift;
  return $self->{'size'};
}

sub getNth {
  my($self,$index) = @_;
  return $self->{'fields'}[$index];
}

# not part of the Ngrams ROLE!!!


sub fields :lvalue{
  $_[0]->{'fields'};
}






package NGram::Array;

sub new {
  my($package) = shift;
  my $self = [@_];
  return bless($self,$package);
}

sub getSize { # nicht length, da perlcore
  my $self = shift;
  return scalar @$self;
}

sub getNth {
  my($self,$index) = @_;
  return $self->[$index];
}

sub DOES{
  return $_[1] eq 'NGram'
    or $_[0]->SUPER::DOES($_[0]);
}

package NGram::PackedString;
use bytes;
no bytes;

sub DOES{
  return $_[1] eq 'NGram'
    or $_[0]->SUPER::DOES($_[0]);
}

our $packstring;
*packstring = \'I1(w/A*)*'; # lenght ngrams

sub new {
  my($package) = shift;
  my $self = \(pack $packstring,scalar @_,map {my $var; ($var = $_) =~ tr /\0/ /; $var} @_);
  return bless($self,$package);
}

sub getSize {
  my $self = shift;
  return unpack 'I1', $$self;
}

sub getNth {
  my($self,$index) = @_;
  return (unpack $packstring, $$self)[$index+1];
}

sub getAll{
  my ($self,@ary) = shift;
  (undef,@ary) = unpack $packstring, $$self;
  return @ary;
}
