#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# get_articles.pl                   falk@lormoral
#                    07 May 2013

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

get_articles.pl

=head1 USAGE

  perl get_articles.pl hash giving links and other information 

=head1 DESCRIPTION

Retrieves the content of the links in the hash given as input argument.

=head1 REQUIRED ARGUMENTS

Perl hash of the following format:

            journal       feed                                          url                       categories/columns (rubrique)
               |           |                                             |                                |
               v           v                                             v                                v  
$VAR1 = {
          'lemonde' => {
                         'http://www.lemonde.fr/rss/tag/europe.xml' => {
                                                                       'http://www.lemonde.fr/economie/article/2013/05/06/suppression-contre-reforme-wall-street-et-la-city-s-affrontent-sur-l-avenir-du-libor_3171426_3234.html' => {
                                                                                                                                                                                                                                     'Europe' => 1
                                                                                                                                                                                                                                   },


=head1 OPTIONS

=cut


my %opts = (
	    'an_option' => 'default value',
	   );

my @optkeys = (
	       'an_option:s',
	      );

unless (GetOptions (\%opts, @optkeys)) { pod2usage(2); };

unless ($ARGV[0]) { pod2usage(2) };

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

print STDERR "Options:\n";
print STDERR Dumper(\%opts);

my $MAX_ARTICLES = 100;

use lib "/home/falk/perl5/lib/perl5";
use Mojo::UserAgent;
use LWP::UserAgent;
use XML::LibXML;
use XML::LibXML::Iterator;

my $lwp_ua = LWP::UserAgent->new;
$lwp_ua->agent('Mozilla/6.0 (compatible;)');

my %ARTNBR_PER_FEED = (
  'lemonde' => 2,
  'lejdd' => 10,
  'slate' => 10,
  'rue89' => 10,
  );

my %GETART_4_JOURNAL = (
  'lemonde' => sub {
    my ($link) = @_;
    
    my $text = '';
    
    my $dom;
    eval { $dom = XML::LibXML->load_html(
  	     location => $link,
  	     # encoding => 'iso-8859-1',
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text;
    }

    ### article content

    my @article_els = $dom->findnodes('//div[@id="articleBody"]', $dom);
    my @blog_entries = $dom->findnodes('//div[@class="entry-content"]//p', $dom);
    
    foreach my $div (@article_els, @blog_entries) {
      my $new_text = $div->textContent();
      next if ($new_text =~ m{ \A \s* \z }xms);
      $text = join('', $text, $new_text, "\n");
    }
    
    return $text;
  },
  'lejdd' => sub {
    my ($link) = @_;
    
    my $text = '';

    my $content = $lwp_ua->get($link)->decoded_content;
    my $dom = Mojo::DOM->new($content);
    
    # scan-content for short articles, article-content for longer ones
    my $article_entries = $dom->find('div[id="scan-content"] p, div[id="article-content"] p, div[id="article-content"] h2');

    for my $e ($article_entries->each()) {
      my $new_text = $e->all_text(0);

      my $type = $e->type();
      $text = join('', $text, $new_text, "\n");
    }

    return $text;
    
  },

  'slate' => sub {
    my ($link) = @_;

    print STDERR "Link: $link\n";
    
    my $text = '';
    
    my $dom;
    eval { $dom = XML::LibXML->load_html(
  	     location => $link,
  	     # encoding => 'iso-8859-1',
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text;
    }

    my @text_content;


    my @article_nodes = $dom->findnodes('//div[@id="article_content" or @class="article_content" or @class="article_text"]');

    print STDERR "Number of article nodes: ", scalar(@article_nodes), "\n";

    foreach my $node (@article_nodes) {

      my $iter = XML::LibXML::Iterator->new( $node );      

      $iter->iterate( 
	sub {
	  my ($iter, $cur)=@_;


	  $iter->last() if ($cur->localname() and $cur->localname() eq 'div' and $cur->hasAttribute('class') and $cur->getAttribute('class') eq 'clearer');

	  $iter->nextNode() unless ($cur->nodeType() == 1);

	  if ($cur->nodeType() == 1) {
	    my $name = $cur->localname();
	    if ($name eq 'p' or $name =~ m{ h [1-4] }xms) {
	      push(@text_content, $cur->textContent());
	    }
	  }
	} 
	);
    }

    $text = join("\n", @text_content);
		 
    return $text;

  },

  'rue89' => sub {
    my ($link) = @_;

    my $text = '';
    
    
    my $dom;
    eval { $dom = XML::LibXML->load_html(
  	     location => $link,
  	     # encoding => 'iso-8859-1',
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text;
    }

    my @text_content;


    my @article_header = map { $_->textContent() } $dom->findnodes('//div[@id="content"]/h1');
    
    my @article_text = map { $_->textContent() } $dom->findnodes('//div[@class="content clearfix"]/p');


    $text = join("\n", @article_header, @article_text);
    return $text;

    my @article_nodes;
    foreach my $node (@article_nodes) {

      my $iter = XML::LibXML::Iterator->new( $node );      

      $iter->iterate( 
	sub {
	  my ($iter, $cur)=@_;

	  $iter->nextNode() unless ($cur->nodeType() == 1);

	  if ($cur->nodeType() == 1) {
	    my $name = $cur->localname();
	    if ($name eq 'p' or $name =~ m{ h [1-4] }xms) {
	      push(@text_content, $cur->textContent());
	    }
	  }
	} 
	);
    }

    $text = join("\n", @text_content);

    return $text;
  },
  );


my %articles = %{ do $ARGV[0] };

use List::Util qw(sum);

my $art_nbr = 0;
my $art_nbr_sel = 0;

foreach my $journal (keys %articles) {

  my $feed_nbr = scalar(keys %{ $articles{$journal} });
  $art_nbr += sum map { scalar(keys %{ $articles{$journal}->{$_} }) }  keys %{ $articles{$journal} };


  print STDERR "Number of articles: $art_nbr\n";
  print STDERR "Number of articles per feed ($feed_nbr):\n";
  foreach my $feed (keys %{ $articles{$journal} }) {
    my $feed_art_nbr = scalar(keys %{ $articles{$journal}->{$feed} });
    print STDERR "$feed: $feed_art_nbr\n";
    
  }
}
  
foreach my $journal (keys %articles) {

  unless ($GETART_4_JOURNAL{$journal}) {
    warn "$journal not supported\n";
    next;
  };
  
  
  foreach my $feed (keys %{ $articles{$journal} }) {
    
    my $count = 0;
    foreach my $link (keys %{ $articles{$journal}->{$feed} }) {
	
      next unless ($link);
      
      my $text = $GETART_4_JOURNAL{$journal}->($link);
      
      # $text = get_lemonde_content($link);
   
      unless ($text) {
	print STDERR "No text for link $link\n";
	next;
      }
 
      if ($text =~ m{ \A \s* \z }xms) {
	print STDERR "Empty text for link $link\n";
	next;
      }


      $text =~ s{ \A \s+ }{}xms;
      $text =~ s{ \s+ \z }{}xms;
      
      my @fields = (
	['URL', $link],
	['Journal', $journal],
	['Flux', $feed],
	['Rubrique', join(', ', keys %{ $articles{$journal}->{$feed}->{$link}->{column} })],
	['Date', $articles{$journal}->{$feed}->{$link}->{date} ],
	['Texte', $text],
	);
      
      foreach my $entry (@fields) {
	my ($dt, $dd) = @{ $entry };
	print join("\t", $dt, $dd), "\n"; 
      }
      
      $count++;
      $art_nbr_sel++;
      
      last if ($ARTNBR_PER_FEED{$journal} and $count >= $ARTNBR_PER_FEED{$journal});
    }
  }
}

print STDERR "Number of selected articles: $art_nbr_sel\n";

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
