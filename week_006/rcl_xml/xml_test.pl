#!/usr/bin/perl
use strict;
use warnings;
use XMLTester;
use YAML::Any qw/Dump/;
use IO::File;

my $tester = XMLTester->new( shift @ARGV );

my $returns = $tester->run( @ARGV );

# Get the memory usage object
my $mu = $tester->mu();
print $mu->dump();
