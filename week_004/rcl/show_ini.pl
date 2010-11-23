#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Config::INI::Reader;
use Config::INI::Writer;
use Data::Dumper;

my $args;

GetOptions( 'a=s'      => \$args->{main}->{a},
            'b=s'      => \$args->{main}->{b},
            'c=s'      => \$args->{main}->{c},
            'config=s' => \$args->{config} );
my $config = $args->{main};

if( $args->{config} and -f $args->{config} ){
  $args = Config::INI::Reader->read_file( $args->{config});
}else{
  Config::INI::Writer->write_file( $args, 'last_config.ini' );
}

print "Config is now:\n" . Dumper( $args ) . "\n";
