#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# critiques.pl                   falk@lormoral
#                    29 May 2013

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

critiques.pl

=head1 USAGE

   

=head1 DESCRIPTION

Stub documentation for critiques.pl, 

=head1 REQUIRED ARGUMENTS

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

my %links;
my %journals;
my %cats;

open (my $fh, '<:encoding(utf-8)', $ARGV[0]) or die "Couldn't open $ARGV[0] for reading: $!\n";

my ($link, $journal, $feed, $cat, $date, $text);
while (my $line = <$fh>) {

  if ($line =~ m{ \A \s* \z }xms) {
    $text .= '<br/>';
    next;
  }

  chomp($line);

  my ($dd, @rest) = split(/\t/, $line);
  if ($dd eq 'URL') {

    if ($link) {

      $links{$link}->{journal} = $journal;
      $links{$link}->{rubrique} = $cat;
      $links{$link}->{date} = $date;

      $journals{$journal}++;
      $cats{$cat}++;

      ($link, $journal, $feed, $cat, $date, $text) = (undef, undef, undef, undef, undef, undef);
    }

    $link = join("\t", @rest);

  } elsif ($dd eq 'Journal') {
    $journal = join("\t", @rest);
  } elsif ($dd eq 'Flux') {
    $feed = join("\t", @rest);
  } elsif ($dd eq 'Rubrique') {
    $cat = join("\t", @rest);
  } elsif ($dd eq 'Date') {
    $date = join("\t", @rest);
  } elsif ($dd eq 'Texte') {
    $text = '<p>'.join("\t", @rest).'</p>';
  } else {
    $text .= "<p>$line</p>";
  }
}

### last entry
if ($link) {
  $links{$link}->{journal} = $journal;
  $links{$link}->{rubrique} = $cat;
  $links{$link}->{date} = $date;


  $journals{$journal}++;
  $cats{$cat}++;


  ($link, $journal, $feed, $cat, $date, $text) = (undef, undef, undef, undef, undef, undef);
}

close $fh;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

print STDERR "Number of collected links: ", scalar(keys %links), "\n";

print STDERR "Number of collected links per journal: \n";

foreach my $journal (sort { $journals{$b} <=> $journals{$a} } keys %journals) {
  print STDERR "$journal: $journals{$journal}\n";
}

print STDERR "Categories:\n";

foreach my $cat (sort { $cats{$b} <=> $cats{$a} } keys %cats) {
  print STDERR "$cat: $cats{$cat}\n";
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
