#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# get_articles_from_feeds_with_paragraphs.pl                   falk@lormoral
#                    06 May 2013

use warnings;
use strict;
use English;

use Data::Dumper;
use Carp;
use Carp::Assert;

use Pod::Usage;
use Getopt::Long;

use utf8;

=head1 NAME

get_articles_from_feeds_with_paragraphs.pl

=head1 USAGE

 perl get_articles_from_feeds_with_paragraphs.pl dna rss xml page
   

=head1 DESCRIPTION

Parses the rss xml page and extracts items, their links and contents and the corresponding column (or topic).


=head1 REQUIRED ARGUMENTS

Feed xml file.


=head1 OPTIONS

=cut


my %opts = (
	    'an_option' => 'default value',
	   );

my @optkeys = (
	       'an_option:s',
	      );

unless (GetOptions (\%opts, @optkeys)) { pod2usage(2); };

unless (@ARGV) { pod2usage(2); };

print STDERR "Options:\n";
print STDERR Dumper(\%opts);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

use XML::LibXML;
use XML::LibXML::Iterator;
use LWP::UserAgent;

my $xpc = XML::LibXML::XPathContext->new;

my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/6.0 (compatible;)');

my $dom = XML::LibXML->load_xml(
  location => $ARGV[0], 
  );


my $feed = $ARGV[0];

my $journal;
if ($feed =~ m{ dna }xms) {
  $journal = 'dna';
} elsif ($feed =~ m{ monde-diplomatique }xms) {
  $journal = 'lmd';
}

my %GETFEED_4_JOURNAL = (
  'dna' => sub {
    my ($item) = @_;

    my ($link, $category, $date) = ('', {}, '');

    $link = ($item->findnodes('./link'))[0]->textContent();


    ### check redirection
    my $request  = HTTP::Request->new( GET => $link );
    my $response = $ua->request($request);
    if ( $response->is_success) {
      $link = $response->request->uri;
    } else {
      print STDERR "Request unsuccessfull\n";
      return ($link, $category, $date);
    }

    foreach my $col ($item->findnodes('category')) {
      my $col_content = $col->textContent();
      $category->{$col_content}++;
    }

    $date = ($item->findnodes('./pubDate'))[0]->textContent();

    return ($link, $category, $date);
  },
  'lmd' => sub {
    my ($item) = @_;

    my ($link, $category, $date) = ('', {}, '');

    $link = ($item->findnodes('./link'))[0]->textContent();
    

    ### check redirection
    my $request  = HTTP::Request->new( GET => $link );
    my $response = $ua->request($request);
    if ( $response->is_success) {
      $link = $response->request->uri;
    } else {
      print STDERR "Request unsuccessfull\n";
      return ($link, $category, $date);
    }

    foreach my $n ($item->findnodes('dc:subject')) {
      my $cat = $n->textContent();
      $category->{$cat}++;
    }

    my $date = ($item->findnodes('dc:date'))[0]->textContent();

    return ($link, $category, $date);

  },
  );


my %GETART_4_JOURNAL = (
  'dna' => sub {
  my ($link) = @_;

  my $text_content = [];


  my $dom;
  eval { $dom = XML::LibXML->load_html(
	   location => $link,
	   # string => $html_string,
	   # encoding => 'iso-8859-1',
	   recover => 2,
	   suppress_warnings => 1,
	   )
  };
  if ($@) {
    warn $@;
    return $text_content;
  }

  ### article content

  my @article_els;
  eval { @article_els = $xpc->findnodes('//div[contains(concat(" ", @class, " "), " article ")]/h1 | //div[contains(concat(" ", @class, " "), " article ")]/h2 | //div[contains(concat(" ", @class, " "), " article ")]/h3 | //div[contains(concat(" ", @class, " "), " article ")]/h4 | //div[contains(concat(" ", @class, " "), " article ")]/p', $dom); } ;
  if ($@) {
    warn "$@ when parsing $link\n";
    return $text_content;
  }

  foreach my $div (@article_els) {
    my $text = $div->textContent();

    next if ($text =~ m{ \A \s* \z }xms);

    my $name = $div->localname();
    push(@{ $text_content }, [ $name, $text ]);
  }

  return $text_content;
  },
  'lmd' => sub {
  my ($link) = @_;

  my $text_content = [];

  my $dom;
  eval { $dom = XML::LibXML->load_html(
	   location => $link,
	   # string => $html_string,
	   # encoding => 'iso-8859-1',
	   recover => 2,
	   suppress_warnings => 1,
	   )
  };
  if ($@) {
    warn $@;
    return $text_content;
  }

  ### article content

  my @articles = $dom->findnodes('//div[contains(@class, "contenu-principal")]');

  my $iter = XML::LibXML::Iterator->new( $articles[0] );

  $iter->iterate(
    sub {
      my ($iter, $cur)=@_;


      $iter->last() if ($cur->localname() and $cur->localname() eq 'div' and $cur->hasAttribute('class') and $cur->getAttribute('class') =~ m{ voiraussi }xms);

      $iter->last() if ($cur->localname() and $cur->localname() eq 'div' and $cur->hasAttribute('class') and $cur->getAttribute('class') =~ m{ toutenbas }xms);

      if ($cur->nodeType() == 1) {
	my $name = $cur->localname();
	if ($name eq 'p' or $name =~ m{ h [1-4] }xms) {
	  my $text = $cur->textContent();
	  $iter->nextNode() if ($text =~ m{ \A \s* \z }xms);
	  push(@{ $text_content }, [$name, $text]);
	}
      }
    },
    );

  return $text_content;

  # my $div = ($dom->findnodes('//div[contains(@class, "contenu-principal")]'))[0];

  # my @p_nodes = $div->findnodes('.//p');

  # foreach my $n (@p_nodes) {
  #   my $new_text = $n->textContent();
  #   $text = join("\n", $text, $new_text);
  # }


  # return $text;


  # $div = ($dom->findnodes('//div[contains(@class, "texte")]'))[0];

  # @p_nodes = $div->findnodes('*[self::h1 or self::h2 or self::h3 or self::p]');

  # foreach my $n (@p_nodes) {
  #   my $new_text = $n->textContent();
  #   $text = join("\n", $new_text);
  # }

  # return $text;
  },
  );

unless ($GETART_4_JOURNAL{$journal}) {
  print STDERR "Unknown journal: $feed\n";
  exit 1;
}

my %articles;
my $art_nbr = 0;
my %links;


my @items = $dom->findnodes('//item');

foreach my $item (@items) {

  my ($link, $category, $date) = $GETFEED_4_JOURNAL{$journal}->($item); 

  next unless ($link);
  next if ($links{$link});
  $links{$link}++;

  next unless ($category);

  foreach my $column (keys %{ $category }) {
    $articles{$journal}->{$feed}->{$link}->{column}->{$column}++;
  }

  if ($date) {
    $articles{$journal}->{$feed}->{$link}->{date} = $date;
  } else {
    warn "No date for $link\n";
  }

}

print STDERR "Number of articles: ", scalar(keys %{ $articles{$journal}->{$feed} }), "\n";

#### create html document for articles
$dom = XML::LibXML->createDocument( "1.0", "UTF-8" );
my $html = $dom->createElement('html');
$html->setAttribute( 'xmnls', "http://www.w3.org/1999/xhtml" );
$html->setAttribute( 'xml:lang', 'fr' );
$dom->setDocumentElement($html);

my $head = $dom->createElement('head');
my $title = $dom->createElement('title');
my $title_text = $dom->createTextNode("Articles du journal $journal");
$title->addChild($title_text);
$head->addChild($title);
$html->addChild($head);

my $body = $dom->createElement('body');
$title = $dom->createElement('h1');
$title->addChild($dom->createTextNode("Articles du journal $journal"));
$body->addChild($title);


foreach my $link (keys %{ $articles{$journal}->{$feed} }) {
	
  next unless ($link);

  my $text_content = $GETART_4_JOURNAL{$journal}->($link);

  next unless ($text_content);
  next unless (@{ $text_content });

  my $rubrique = join(', ', keys %{ $articles{$journal}->{$feed}->{$link}->{column} });
      
  my @fields = (
    # ['URL', $link],
    ['Journal', $journal],
    # ['Flux', $feed],
    ['Rubrique', $rubrique],
    ['Date', $articles{$journal}->{$feed}->{$link}->{date} ],
    # ['Texte', $text],
    );

  my $dl = $dom->createElement('dl');

  foreach my $click_ref (['URL', $link], ['Flux', $feed]) { 

    my ($dt_text, $dd_text) = @{ $click_ref };
    
    my $dt = $dom->createElement('dt');
    $dt->addChild($dom->createTextNode($dt_text));
    $dl->addChild($dt);
	
    my $dd = $dom->createElement('dd');
    my $a = $dom->createElement('a');
    $a->setAttribute('href', $dd_text);
    $a->setAttribute('target', '_blank');
    $a->addChild($dom->createTextNode($dd_text));
    $dd->addChild($a);
    $dl->addChild($dd);
  }

  foreach my $entry (@fields) {
    my ($dt_text, $dd_text) = @{ $entry };
    
    my $dt = $dom->createElement('dt');
    $dt->addChild($dom->createTextNode($dt_text));
    $dl->addChild($dt);
    
    my $dd = $dom->createElement('dd');
    $dd->addChild($dom->createTextNode($dd_text));
    $dl->addChild($dd);
  }

  $body->addChild($dl);

  my $h1 = $dom->createElement('h1');
  $h1->addChild($dom->createTextNode("Texte de l'article"));
  $body->addChild($h1);

  $body->addChild($dom->createElement('hr'));
  
  my $div = $dom->createElement('div');
  $div->setAttribute('styĺe', 'background-color: silver');

  foreach my $text_ref (@{ $text_content }) {
    my ($name, $content) = @{ $text_ref };
    my $el = $dom->createElement($name);
    $el->addChild($dom->createTextNode($content));
    $div->addChild($el);
  }

  $body->addChild($div);
  
  $body->addChild($dom->createElement('hr'));
  
  
}

$html->addChild($body);
my $file_name = join('_', $journal, 'articles');
$file_name = join('.', $file_name, 'html');
# print $dom->toString(1);
$dom->toFile($file_name, 1);


1;





__END__

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

created by template.el.

It looks like the author of this script was negligent
enough to leave the stub unedited.


=head1 AUTHOR

Ingrid Falk, E<lt>E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Ingrid Falk

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
