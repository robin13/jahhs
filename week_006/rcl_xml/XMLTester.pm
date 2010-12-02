package XMLTester;
use strict;
use warnings;
use XML::Smart;
use XML::Simple;
use XML::Twig;
use XML::Parser;
use Memory::Usage;
use YAML::Any qw/Dump/;
use Data::Dumper;
use utf8;

sub new{
    my $class = shift;
    my $xml_file = shift;
    if( ! $xml_file ){
        die( "XML file not defined\n" );
    }
    if( ! -f $xml_file ){
        die( "XML file does not exist\n" );
    }
    my $self = {};
    $self->{xml_file} = $xml_file;
    $self->{out_fmt} = "%-10s %-10s %-10s %s\n";

    $self->{mu} = Memory::Usage->new();
    $self->{mu}->record( 'XMLTester START' );

    bless $self, $class;
    return $self;
}

sub run{
    my $self = shift;
    my @test_list = @_;

    # If no test list passed, test all
    if( scalar( @test_list ) == 0 ){
        @test_list =  qw/xmlparser twig smart libxml simple/;
    }


    my %returns;
    foreach( @test_list ){
        print "Starting test_$_\n";
        $self->{mu}->record( "test_$_ START" );
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
        $self->{mu}->record( "test_$_ END" );
        print "Finished test_$_\n";
    }

    return \%returns;
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
    my $fh = IO::File->new( 'output_smart.txt', 'w' );
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
    my $fh = IO::File->new( 'output_twig.txt', 'w' );
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
    $twig->purge();

    $fh->close();
}

sub parse_filme{
    my( $t, $section ) = @_;
    my $line = undef;
    printf { $t->{tester_fh} } $t->{tester_out_fmt},
      $section->first_child( 'Nr' )->text(),
      $section->first_child( 'Sender' )->text(),
      $section->first_child( 'Thema' )->text(),
      $section->first_child( 'Titel' )->text();
}


sub test_simple{
    my $self = shift;

    my $fh = IO::File->new( 'output_simple.txt', 'w' );
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
    my $fh = IO::File->new( 'output_xmlparser.txt', 'w' );
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
                print "Missing fields for $hash{Nr}\n";
            }
        }
        $idx++;
    }
    $fh->close();
    $self->{mu}->record( 'test_xmlparser just before end' );
}


sub mu{
    my $self = shift;
    return $self->{mu};
}
1;
