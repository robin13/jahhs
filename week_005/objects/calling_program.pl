#!/usr/bin/perl -w
# A programm calling the NGram objects
# Patrick Seebauer

use strict;
use utf8;
use 5.01;
use NGram;

use Sentence;
use open ':std', OUT => 'encoding(utf8)';
{
  {
    my $ngram = NGram->new(qw(eins zwei drei));
    $ngram->getSize();
  }

  my @ngrams  =(NGram->new(qw(eins zwei drei))
		,NGram::Array->new(qw(vier fünf sechs))
		,NGram::PackedString->new(qw(sieben acht neun zehn))
		,Sentence->new(split /\s|(?=\pP)/,"Ein Männlein steht im Walde."));

  my $i;
  foreach (@ngrams) {
    printf(<<'OUTPUT'
size %d: “$_->[%d]”: %-6s| ref: %-20s; does ngram? %s.
OUTPUT
	   ,$_->getSize()
	   ,++$i, $_->getNth($i)
	   ,ref $_
	   , $_->DOES('NGram')?'yes':'no');
  }
}
