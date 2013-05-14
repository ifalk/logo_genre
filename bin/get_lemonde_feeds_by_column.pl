#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# get_lemonde_feeds_by_cat.pl                   falk@lormoral
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

get_lemonde_feeds_by_cat.pl

=head1 USAGE

 perl get_lemonde_feeds_by_column.pl lemonde rss html page   

=head1 DESCRIPTION

Parses the html page given as input and collects the links and associated column names.

=head1 REQUIRED ARGUMENTS

Html file (or url) containing list of RSS feeds with corresponding column.

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

my $journal = 'lemonde';

use XML::LibXML;

my $dom = XML::LibXML->load_html(
  location => $ARGV[0], 
  recover => 2,
  encoding => 'iso-8859-1',
  );

my @rss = $dom->findnodes('//td[@class="lien_texte"]/a');


my %feeds;

foreach my $node (@rss) {
  my $link = $node->getAttribute('href');
  my $column_name = $node->textContent();

  next if ($column_name =~ m{(vidéo|podcast)}i);

  $column_name =~ s{ \A \s+ }{}xms;
  $column_name =~ s{ \s+ \z }{}xms;
  $column_name =~ s{ \s+ }{ }xmsg;

  $feeds{$link}->{$column_name}++;
}

my %articles;
my %links;

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/6.0 (compatible;)');


foreach my $feed (keys %feeds) {

  print STDERR "Parsing $feed\n";

  my $dom;
  eval { $dom = XML::LibXML->load_xml(
	   location => $feed,
	   )
  };
  if ($@) {
    warn $@;
    next;
  }
  next unless ($dom);


  my @items = $dom->findnodes('//item');

  foreach my $item (@items) {

    my $link = ($item->findnodes('./link'))[0]->textContent();

    next if ($links{$link});

    ### check redirection
    my $request  = HTTP::Request->new( GET => $link );
    my $response = $ua->request($request);
    if ( $response->is_success) {
      $link = $response->request->uri;
    } else {
      $links{$link}++;
      print STDERR "Request unsuccessfull\n";
      next;
    }
    next if ($links{$link});

    $links{$link}++;

    foreach my $column (keys %{ $feeds{$feed} }) {
      $articles{$journal}->{$feed}->{$link}->{column}->{$column}++;
    }

    my $date = ($item->findnodes('./pubDate'))[0]->textContent();
    if ($date) {
      $articles{$journal}->{$feed}->{$link}->{date} = $date;
    } else {
      warn "No date for $link\n";
    }
  }

}

print Dumper(\%articles);

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