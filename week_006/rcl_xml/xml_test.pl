#!/usr/bin/perl
use strict;
use warnings;
use XMLTester;
use YAML::Any qw/Dump/;
use IO::File;
use Getopt::Long;

my $args;
GetOptions(
           'out_dir=s' => \$args->{out_dir},
           'xml_file=s' => \$args->{xml_file},
);

my $tester = XMLTester->new( $args );
my $returns = $tester->run( @ARGV );

# Get the memory usage object
my $mu = $tester->mu();
print $mu->dump();
