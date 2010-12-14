#!/usr/bin/perl
use strict;
use warnings;
use integer;


my @values = ( 9.11, 9.5, 9.9 );

my $by_int = 3;
my $by_float = 3.9;
print "use integer\n";
foreach( @values ){
    printf "%6s * %6s = %s\n", $_, $by_int, ( $_ * $by_int );
    printf "%6s * %6s = %s\n", $_, $by_float, ( $_ * $by_float );
}
