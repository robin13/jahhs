#!/usr/bin/perl
use strict;
use warnings;
use XMLTester;
use YAML::Any qw/Dump/;
use IO::File;
use Getopt::Long;

my $args;
my @run_tests;
GetOptions(
           'out_dir=s'  => \$args->{out_dir},
           'xml_file=s' => \$args->{xml_file},
           'run_test=s' => \@run_tests,
           'use_mu'     => \$args->{use_mu},
);

my $tester = XMLTester->new( $args );

my( $returns, $times) = $tester->run( @run_tests );

# Get the memory usage object
my $mu = $tester->mu();

print "Report for XML processing carried out on $args->{xml_file}\n";
print $mu->report();

print "\nTimes:\n";
my $smallest = undef;
my $times_fmt = "%-10s %0.5fs (% 7.1f%%)\n";
foreach( sort{ $times->{$a} <=> $times->{$b} }( keys( %$times ) ) ){
    if( ! $smallest ){
        $smallest = $times->{$_};
    }
    printf( $times_fmt, $_, $times->{$_}, ( 100 * ( $times->{$_} / $smallest ) ) );
}
