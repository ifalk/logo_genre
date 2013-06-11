#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# get_articles_with_paragraphs.pl                   falk@lormoral
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

get_articles_with_paragraphs.pl

=head1 USAGE

  perl get_articles_with_paragraphs.pl hash giving links and other information 

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
  'presseurop' => 15,
  'lequipe' => 5,
  'lalibre' => 6,
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

    my $text_content;


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
	      my $text = $cur->textContent();
	      $iter->nextNode() if ($text =~ m{ \A \s* \z }xms);
	      push(@{ $text_content }, [$name, $text]);
	    }
	  }
	} 
	);
    }

    return $text_content;

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

    my $text_content;


    # my @article_header = $dom->findnodes('//div[@id="content"]/h1');

    # foreach my $el (@article_header) {
    #   my $text = $el->textContent();
    #   next if ($text =~ m{ \A \s* \z }xms);
    #   push(@{ $text_content }, ['h1', $el->textContent()]);
    # }


    my @div_nodes = $dom->findnodes('//div[@id="content"]');

    print STDERR "Number of div nodes: ", scalar(@div_nodes), "\n";

    if (@div_nodes) {

      # if (@p_nodes) {
      
      # 	foreach my $p_node (@p_nodes) {

      # 	  my $text = $p_node->textContent();
      # 	  next if ($text =~ m{ \A \s* \z }xms);
      # 	  push(@{ $text_content }, ['p', $text]);
      # 	}
	

      my $iter = XML::LibXML::Iterator->new( $div_nodes[0] );      
    
      $iter->iterate( 
	sub {
	  my ($iter, $cur)=@_;
	    
	  if ($cur->nodeType() == 1) {
	    my $name = $cur->localname();

	    if ($name eq 'div') {
	      if ($cur->hasAttribute('id') and $cur->getAttribute('id') eq 'commentaires') {
		$iter->last();
	      }
	    }

	    if ($name eq 'p' or $name =~ m{ h [1-4] }xms) {
	      my $text = $cur->textContent();
	      unless ($text =~ m{ \A \s* \z }xms) {
		push(@{ $text_content }, [$name, $text]);
	      }
	    }
	  }
	} 
	);
    }
  
    return $text_content;
  
  },

  'presseurop' => sub {
    my ($link) = @_;

    my $text_content;

    my $dom;
    eval { $dom = XML::LibXML->load_html(
  	     location => $link,
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text_content;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text_content;
    }

    my @article_header = $dom->findnodes('//article/hgroup/h1');
    
    foreach my $node (@article_header) {
      my $text = $node->textContent();

      unless ($text =~ m{ \A \s* \z }xms) {
	push(@{ $text_content }, ['h1', $text]);
      }
    }


    my @article_nodes = $dom->findnodes('//article//div[@class="panel"]');

    if (@article_nodes) {
      my $iter = XML::LibXML::Iterator->new( $article_nodes[0] );      
      $iter->iterate( 
	sub {
	  my ($iter, $cur)=@_;
	  
	  if ($cur->nodeType() == 1) {
	    my $name = $cur->localname();
	    
	    if ($name eq 'aside') {
	      $iter->last();
	    }

	    if ($name eq 'p') {
	      my $text = $cur->textContent();
	      unless ($text =~ m{ \A \s* \z }xms) {
		push(@{ $text_content }, [$name, $text]);
	      }
	    }
	  }
	} 
	)
    };
  
    return $text_content;
  },

  'lequipe' => sub {
    my ($link) = @_;

    my $text_content = [];

    my $dom;

    my $content = $lwp_ua->get($link)->decoded_content;

    eval { $dom = XML::LibXML->load_html(
  	     string => $content,
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text_content;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text_content;
    }

    my @article_nodes = $dom->findnodes('//article');

    foreach my $article (@article_nodes) {

      my $iter = XML::LibXML::Iterator->new( $article );

      while ($iter->nextNode()) {

	my $current = $iter->current();
	if ($current->nodeType() eq '1') {
	  my $name = $current->localname();
	  if ($name =~ m{ h[1-4] }xms) {
	    my $text = $current->textContent();
	    unless ($text =~ m{ \A \s* \z }xms) {
	      $text =~ s{ \s+ }{ }xms;
	      push( @{ $text_content }, [ $name, $text ] );
	    }
	  } elsif ($name eq 'div') {
	    if ($current->hasAttribute('class')) {
	      my $class = $current->getAttribute('class');
	      if ($class =~ m{ paragr \b }xms) {

		# my @children = $current->childNodes();

		# my $text = '';
		# foreach my $child (@children) {
		#   if ($child->nodeType() eq '3') {
		#     my $new_text = $child->data();
		#     next if ($text =~ m{ \A \s* \z });
		#     $text = join(' ', $text, $new_text);
		#   } elsif ($child->nodeType() eq '1') {
		#     my $name = $child->localname();
		#     if ($name eq 'br') {
		#       if ($text) {
		# 	push (@{ $text_content }, [ 'p', $text ]);
		# 	$text = '';
		#       }
		#     } else {
		#       my $new_text = $child->textContent();
		#       next if ($text =~ m{ \A \s* \z });
		#       $text = join(' ', $text, $new_text);
		#     }
		#   }
		# }

		my $text = $current->textContent();

		if ($text and $text !~ m{ \A \s* \z }xms) {
		  push (@{ $text_content }, [ 'p', $text ]);
		}

	      }
	    } elsif ($current->hasAttribute('id')) {
	      my $id = $current->getAttribute('id');
	      last if ($id eq 'new_bloc_bas_breve');
	      last if ($id eq 'ensavoirplus');
	    }
	  }
	}
      }
    }

    return $text_content;
  },

  'lalibre' => sub {
    my ($link) = @_;
    
    my $text_content;
    
    my $dom;
    
    my $content = $lwp_ua->get($link)->decoded_content;
    
    eval { $dom = XML::LibXML->load_html(
  	     string => $content,
  	     recover => 2,
  	     suppress_warnings => 1,
  	     )
    };
    if ($@) {
      warn $@;
      return $text_content;
    }
    
    unless ($dom) {
      print STDERR "Unsuccessful parse\n";
      return $text_content;
    }

    my $header = ($dom->findnodes('//h1'))[1]->textContent();
    $header =~ s{ \A \s+ }{}xms;
    $header =~ s{ \s+ \z }{}xms;
    $header =~ s{ \s+ }{ }xmsg;
    $header =~ s{ \222 }{'}xmsg;
    
    unless ($header =~ m{ \A \s* \z }xms) {
      push(@{ $text_content }, [ 'h1', $header ]);
    }

    my @hat = $dom->findnodes('//div[@id="articleHat"]');

    foreach my $h_node (@hat) {
      my $text = $h_node->textContent();
      unless ($text =~ m{ \A \s* \z }xms) {
	$text =~ s{ \A \s+ }{}xms;
	$text =~ s{ \s+ \z }{}xms;
	$text =~ s{ \s+ }{ }xmsg;
	$text =~ s{ \222 }{'}xmsg;
	push(@{ $text_content }, [ 'h2', $text ]);
      }
    }

    my @article = $dom->findnodes('//div[@id="articleText"]/p');

    foreach my $a_node (@article) {

      my $text = $a_node->textContent();
      $text =~ s{ \A \s+ }{}xms;
      $text =~ s{ \s+ \z }{}xms;
      $text =~ s{ \s+ }{ }xmsg;
      $text =~ s{ \222 }{'}xmsg;
      push(@{ $text_content }, [ 'p', $text ]);

    }

    return $text_content;
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
  
  my $dom = XML::LibXML->createDocument( "1.0", "UTF-8" );
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

  $body->addChild($dom->createElement('hr'));


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

      unless (@{ $text }) {
	print STDERR "No text for link $link\n";
	next;
      }

      my $rubrique = join(', ', keys %{ $articles{$journal}->{$feed}->{$link}->{column} });

      #### slate's columns are in iso-8859-1 (although the xml encoding is utf-8)
      use Encode;

      my %to_fix_encoding = (
	'slate' => 1,
	'rue89' => 1,
	'lequipe' => 1,
	);

      if ($to_fix_encoding{$journal}) {
	$rubrique = encode('utf-8', $rubrique);
      }

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

      my $div = $dom->createElement('div');
      $div->setAttribute('styĺe', 'background-color: silver');

      foreach my $text_ref (@{ $text }) {
	my ($name, $content) = @{ $text_ref };
	my $el = $dom->createElement($name);
	$el->addChild($dom->createTextNode($content));
	$div->addChild($el);
      }
      
      $body->addChild($div);
      
      $body->addChild($dom->createElement('hr'));
      
      $count++;
      $art_nbr_sel++;
      
      last if ($ARTNBR_PER_FEED{$journal} and $count >= $ARTNBR_PER_FEED{$journal});
    }
  }

  $html->addChild($body);
  my $file_name = join('_', $journal, 'articles');
  $file_name = join('.', $file_name, 'html');
  $dom->toFile($file_name, 1);
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
