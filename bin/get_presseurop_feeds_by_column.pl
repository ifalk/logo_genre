#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# get_presseurop_feeds_by_column.pl                   falk@lormoral
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

get_presseurop_feeds_by_column.pl

=head1 USAGE

 perl get_presseurop_feeds_by_columns.pl presseurop rss html page   
   

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

use XML::LibXML;

my $dom = XML::LibXML->load_html(
  location => $ARGV[0], 
  recover => 2,
  );


my @rss = $dom->findnodes('//h2[text()="Flux généraux"]/following-sibling::ul//a');

my $base_url = 'http://www.presseurop.eu';

foreach my $node (@rss) {

  my $rel_link = $node->getAttribute('href');
  my $link = join('', $base_url, $rel_link);

  my $column_name = $node->textContent();
  $column_name =~ s{ \A \s+ }{}xms;
  $column_name =~ s{ \s+ \z }{}xms;
  $column_name =~ s{ \s+ }{ }xmsg;

  $column_name = join('; ', 'Généraux', $column_name);

  print join(', ', $column_name, $link), "\n";

}

@rss = $dom->findnodes('//h3/following-sibling::ul/li[1]/a');

foreach my $node (@rss) {
  my $column_name = $node->textContent();
  $column_name =~ s{ \A \s+ }{}xms;
  $column_name =~ s{ \s+ \z }{}xms;
  $column_name =~ s{ \s+ }{ }xmsg;

  my $rel_link = $node->getAttribute('href');
  my $link = join('', $base_url, $rel_link);

  print join(', ', $column_name, $link), "\n";
}

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
