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

use LWP::UserAgent;
use XML::LibXML;

my $lwp_ua = LWP::UserAgent->new;
$lwp_ua->agent('Mozilla/6.0 (compatible;)');

sub get_lemonde_content {
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
}


my %articles = %{ do $ARGV[0] };

use List::Util qw(sum);

my $feed_nbr = scalar(keys %{ $articles{lemonde} });
my $art_nbr = sum map { scalar(keys %{ $articles{lemonde}->{$_} }) }  keys %{ $articles{lemonde} };


print STDERR "Number of articles: $art_nbr\n";
print STDERR "Number of articles per feed ($feed_nbr):\n";
foreach my $feed (keys %{ $articles{lemonde} }) {
  my $feed_art_nbr = scalar(keys %{ $articles{lemonde}->{$feed} });
  print STDERR "$feed: $feed_art_nbr\n";

}

$art_nbr = 0;

foreach my $journal (keys %articles) {

  foreach my $feed ((keys %{ $articles{$journal} })) {

    foreach my $link ((keys %{ $articles{$journal}->{$feed} })[0..2]) {

      next unless ($link);

      my $text = '';
      if ($link =~ m{ lemonde }xmsg) {

	$text = get_lemonde_content($link);

	next unless ($text);
	next if ($text =~ m{ \A \s* \z }xms);

	$text =~ s{ \A \s+ }{}xms;
	$text =~ s{ \s+ \z }{}xms;

	$art_nbr++;

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

      }
    }
  }
}

print STDERR "Number of articles: $art_nbr\n";

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
