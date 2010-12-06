package XMLTester;
use strict;
use warnings;

# This is an XML processor benchmarker.
# XML parsers can be tested against each other to compare their respective processing time
# and memory usage
# A standard XML is taken as input (see sample_[small|medium|big].xml for the input
# The "Filme" elements are processed and a sub-section of this element is printed out to
# a csv file for each processor.
# This is a fairly simple, and so repeatable processing step which should make comparison
# of the processing effectiveness and output meaningful and relatable to real-life systems.

use XML::Smart;
use XML::Simple;
use XML::Twig;
use XML::Parser;
use Memory::Usage;
use File::Spec::Functions;
use Time::HiRes qw/time/;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    bless $self, $class;

    foreach( qw/xml_file out_dir/ ){
        if( ! $args->{$_} ){
            die( "$_ is a required argument\n" );
        }
        $self->{$_} = $args->{$_};
    }

    if( ! -f $args->{xml_file} ){
        die( "File $args->{xml_file} does not exist\n" );
    }

    if( ! -d $args->{out_dir} ){
        die( "Dir $args->{out_dir} does not exist\n" );
    }


    $self->{out_fmt} = "%-10s %-10s %-10s %s\n";

    $self->{use_mu} = $args->{use_mu} || 0;
    $self->{mu} = $self->mu();
    $self->{mu}->record( 'XMLTester START' );

    return $self;
}

sub run{
    my $self = shift;
    my @test_list = @_;

    # If no test list passed, test all
    if( scalar( @test_list ) == 0 ){
        @test_list =  qw/xmlparser twig smart simple/; # libxml
    }


    my %returns;
    my %times;
    foreach( @test_list ){
        print "Starting test_$_\n";
        $self->{mu}->record( "test_$_ START" );
        my $time_start = time();
        if( $_ eq 'twig' ){
            $returns{$_} = $self->test_twig();
        }elsif( $_ eq 'smart' ){
            $returns{$_} = $self->test_smart();
        }elsif( $_ eq 'libxml' ){
            $returns{$_} = $self->test_libxml();
        }elsif( $_ eq 'simple' ){
            $returns{$_} = $self->test_simple();
        }elsif( $_ eq 'xmlparser' ){
            $returns{$_} = $self->test_xmlparser();
        }else{
            die( "No test named $_\n" );
        }
        $times{$_} = time() - $time_start;

        $self->{mu}->record( "test_$_ END" );
        print "Finished test_$_\n";
    }

    return \%returns, \%times;
}


# All of the following methods are designed to read in an XML file in a known format
# (the Mediathek library), and return some details in a given format, recording memory
# usage, and if run with DProf, to compare the work (cpu time), and memory consumed
sub test_smart{
    my $self = shift;

    # XML::Smart sucks in the whole XML file
    my $xml = new XML::Smart( $self->{xml_file},
                              'XML::Smart::Parser',
                             ) ;

    # We want to look at the Filme section
    if( ! $xml->{Mediathek}->{Filme} ){
        die( "Could not find Mediathek->Filme in XML\n" );
    }

    # Open the file for output - we know our source is in utf8
    my $fh = IO::File->new( catfile( $self->{out_dir}, 'output_smart.txt' ), 'w' );
    $fh->binmode(':encoding(UTF-8)');

    # We know that the Filme section should be an array(ref)
    foreach( @{ $xml->{Mediathek}->{Filme} } ){
        if( $_->{Nr} && $_->{Sender} && $_->{Thema} && $_->{Titel} ){
            # Generate the output (Smart does the decoding for us!)
            printf $fh $self->{out_fmt},
              $_->{Nr}->content(),
              $_->{Sender}->content(),
              $_->{Thema}->content(),
              $_->{Titel}->content();
        }
    }
    $fh->close();
    $self->{mu}->record( 'test_smart just before end' );
}


sub test_twig{
    my $self = shift;

    # Open the file for output - we know our source is in utf8
    my $fh = IO::File->new( catfile( $self->{out_dir}, 'output_twig.txt' ), 'w' );
    $fh->binmode( ':encoding(UTF-8)' );

    my $twig = XML::Twig->new(
        twig_handlers =>
          { Filme   => \&parse_filme,
        },
       );


    # This is a dirty way of letting the Twig object have access to the filehandle
    # for writing out
    $twig->{tester_fh} = $fh;
    $twig->{tester_out_fmt} = $self->{out_fmt};

    # Initiate the actual parsing - the \&parse_filme method does the actual 
    # writing to file
    $twig->parsefile( $self->{xml_file} );


    # This is important to free memory - let's see how much memory we actually used.
    $self->{mu}->record( 'test_twig just before purge' );

    # Important to purge at the end to free up memory
    $twig->purge();

    $fh->close();
}

sub parse_filme{
    my( $t, $section ) = @_;
    my $line = undef;
    my %found;
    $found{Nr} = $section->first_child( 'Nr' );
    if( ! $found{Nr} ){
        warn( "No Nr found...\n" );
        return undef;
    }
    foreach( qw/Sender Thema Titel/ ){
        $found{$_} = $section->first_child( $_ );
        if( ! $found{$_} ){
            warn( "Something missing for entry " . $found{Nr}->text() . "\n" );
            return undef;
        }
    }

    printf { $t->{tester_fh} } $t->{tester_out_fmt},
      $found{Nr}->text(),
      $found{Sender}->text(),
      $found{Thema}->text(),
      $found{Titel}->text();

    # Purge the section
    # Always purg the twigs you are finished with, otherwise memory usage will balloon!!!
    $section->purge();
}


sub test_simple{
    my $self = shift;

    my $fh = IO::File->new( catfile( $self->{out_dir}, 'output_simple.txt' ), 'w' );
    $fh->binmode( ':encoding(UTF-8)' );

    #XML::Simple does not work with Devel::DProf ... :-(
    my $ref = XMLin( $self->{xml_file} );
    foreach my $entry( @{ $ref->{Filme} } ){
        if( $entry->{Nr} and $entry->{Sender} and $entry->{Thema} and $entry->{Titel} ){
            printf $fh $self->{out_fmt}, $entry->{Nr}, $entry->{Sender}, $entry->{Thema}, $entry->{Titel};
        }else{
            warn( "Something missing for entry $entry->{Nr}\n" );
        }
    }
    $fh->close();
}

sub test_libxml{
    my $self = shift;

    warn( "test_libxml not implemented yet\n" );
}

sub test_xmlparser{
    my $self = shift;

    # Open the file for output - we know our source is in utf8
    my $fh = IO::File->new( catfile( $self->{out_dir}, 'output_xmlparser.txt' ), 'w' );
    $fh->binmode( ':encoding(UTF-8)' );

    # initialize parser and read the file
    # Style "Tree" does a conversion to a hash/array tree
    my $parser = new XML::Parser( Style => 'Tree' );
    my $tree = $parser->parsefile( $self->{xml_file} );

    # The tree built by XML::Parse is very strange... needs analysis to generate
    # this complicated parsing form, specifically for our format
    # Also: how to make it actually output Unicode...???

    my $idx = 0;
  LEVEL1:
    while( $idx < scalar( @{ $tree->[1] } ) ){
        my $element = $tree->[1]->[$idx];
        if( $element eq 'Filme' ){
            my %hash;
            $element = $tree->[1]->[++$idx];
            my $sub_idx = 0;
            while( $sub_idx < scalar( @$element ) ){
                my $sub_element = $element->[$sub_idx];
                if( ! ref( $sub_element ) ){
                    my $nxt_sub_element = $element->[++$sub_idx];
                    $hash{$sub_element} = $nxt_sub_element->[2];
                }
                $sub_idx++;
            }
            if( $hash{Nr} and $hash{Sender} and $hash{Thema} and $hash{Titel} ){
                printf $fh $self->{out_fmt}, $hash{Nr}, $hash{Sender},$hash{Thema}, $hash{Titel};
            }else{
                warn( "Something missing for entry " . $hash{Nr} . "\n" );
            }
        }
        $idx++;
    }
    $fh->close();
    $self->{mu}->record( 'test_xmlparser just before end' );
}


sub mu{
    my $self = shift;
    if( ! $self->{mu} ){
        if( $self->{use_mu} == 1 ){
            $self->{mu} = Memory::Usage->new();
        }else{
            $self->{mu} = MemoryUsageStub->new();
        }
    }
    return $self->{mu};
}



package MemoryUsageStub;
use strict;
use warnings;

sub new{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub record{
    # Do nothing - just a stub
}

sub report{
    return "Using MemoryUsageStub - no report available!\n";
}

1;
