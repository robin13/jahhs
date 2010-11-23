#!/usr/bin/perl
use strict;
use warnings;
use YAML::Any qw/Dump DumpFile/;
use Data::Dumper;
use XML::Dumper;
use Dumpvalue;

my @array = qw/a b c/;
my $data = { 'MyArray' => [ qw/a b c/ ],
             'MyHash'  => { 1 => 'one',
                            2 => 'two',
                            3 => [ 'x', 'y', 'z' ],
               } };

bless $data, 'test_obj';

print Dumper( $data ) . "\n\n";

print Dump( $data ) . "\n\n";

my $dump = XML::Dumper->new();
print $dump->pl2xml( $data );

print "\n\n";
my $dumper = Dumpvalue->new;
$dumper->dumpValues( $data );
         
