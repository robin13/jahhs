#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# DBI for database connection
use DBI;
use DBD::SQLite;

# For higher resolution time measurement
use Time::HiRes qw/time/;

my( $dbfile, $limit, $city );

GetOptions ("db=s"    => \$dbfile,
            "limit=i" => \$limit,
            "city=s"  => \$city );

# Some defaults
$dbfile ||= './data.db';
$city   ||= 'Hattiesburg';

# Check the database file exists (sqlite creates a database if it doesn't exist yet!)
if( ! -f $dbfile ){
    die( "dbfile does not exist: $dbfile\n" );
}

# Which columns do we want to see
my @cols = qw/number gender givenname surname streetaddress city country/;

# Connect to the database
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

# Turn off fsyncs (!!NO LONGER ACID!!)
$dbh->do( 'PRAGMA synchronous = OFF' );

# Allow the database to use 10MB of cache (default 2MB)
$dbh->do("PRAGMA cache_size = 10000");


# Make an SQL - ALWAYS use bind variables!  There is no good excuse not to!
my $sql = 'SELECT ' . join( ', ', @cols ) . ' FROM fakenames WHERE city=?';
my @args = ( $city );
if( $limit ){
  $sql .= ' LIMIT ?';
  push( @args, $limit );
}

# Start timer and prepare statement
my $time_start = time();
my $sth = $dbh->prepare( $sql );

# Execute with the bind variables
$sth->execute( @args );

# Generate the output (send to $out first so time not affected by output to terminal)
my $out;
while( my $row = $sth->fetchrow_hashref ){
    $out .= join( ',', map{ $row->{$_} } @cols ) . "\n";
}

print $out;
print "Time taken: " . ( time() - $time_start ) . "\n";
