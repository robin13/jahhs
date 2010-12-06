package Sentence;
use base 'NGram';
# oder @ISA = ('NGram')
use strict;

our $eos_sign = (__PACKAGE__.'eos_sign');

sub new {
  my($package,$this_eos_sign) = (shift, pop);
  my $self = $package->SUPER::new(@_);
  $self->{$eos_sign} = $this_eos_sign;
  return bless($self,$package);
}

sub getRealSize {
  return $_[0]->SUPER::getSize(@_) + 1;
}

sub getNth {
  my ($self, $index)= (shift, @_);
  return $self->SUPER::getNth(@_) //
    ($index == $self->getSize() #könnte saubrerer sein
     ? $self->{$eos_sign}
     : undef );
}
1;
