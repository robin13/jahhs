#!/usr/bin/perl
use strict;
use warnings;

my $int = 1 << 1;
printf( "%-10s: %s\n", "1 << 1", $int );
$int = 1 << 4;
printf( "%-10s: %s\n", "1 << 4", $int );
$int <<= 4;
printf( "%-10s: %s\n", "<<=4", $int );

$int >>= 4;
printf( "%-10s: %s\n", ">>=2", $int );

print "------------------------\n";
$int = 1 << 31;
printf( "%-10s: %s\n", "1 << 31", $int );
$int = 1 << 32;
printf( "%-10s: %s\n", "1 << 32", $int );
$int = 1 << 33;
printf( "%-10s: %s\n", "1 << 33", $int );



