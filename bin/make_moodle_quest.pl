#!/usr/bin/perl
# -*- mode: perl; buffer-file-coding-system: utf-8 -*-
# make_moodle_quest.pl                   falk@lormoral
#                    07/05/2013

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

make_moodle_quest.pl

=head1 USAGE

  perl make_moodle_quest.pl csv file containing article data

=head1 DESCRIPTION

Generates 3 moodle questions for each article provided in the csv file given as argument.

The first question is of type I<description> and gives 

=over 2

=item the URL of the article

=item the journal the article appeared in

=item the feed the article appeared in

=item the category (or column) of the feed/article

=item the content of the article


=back


The second question is of type I<multiple choice> with check boxes to assess the genre of the given article.

The third question is of type I<shortanswer> and allows the user to provide a remark or comment.

The questionnaire is produced as an xml file in the moodle XML format. 



=head1 REQUIRED ARGUMENTS

A tab separated file in the format shown below.

  URL	http://www.lemonde.fr/livres/article/2013/04/19/freres-d-infortune_3162253_3260.html
  Journal	lemonde
  Flux	http://www.lemonde.fr/rss/tag/livres.xml
  Rubrique	Livres
  Texte	

Impossible de dénicher duo plus improbable. Fuzz est un ours en peluche envoyé à la poubelle par un enfant pervers. Pluck, un coq d'élevage promis à l'abattage, dont il parvient à s'échapper. Compagnons de benne à ordures, les deux survivants errent dans un monde où le cynisme et la férocité frappent à chaque coin de rue. Treize ans après leur première histoire, nos deux amis voient leur chemin se séparer : devenu livreur de sandwichs au lard, le premier se fait torturer par une bande de jouets jaloux, puis recueillir par un doux cinglé. Le second intègre une troupe d'animaux gladiateurs qui s'écharpent dans un cirque ambulant. Burlesques, picaresques et grotesques, cruelles aussi, les péripéties de Fuzz et Pluck racontent, sous le trait acéré de l'Américain Ted Stearn, la lâcheté humaine et la cupidité, mais aussi le droit à la différence, à la manière de Freaks. A lire urgemment.


=head1 OPTIONS

=back

=cut


my %opts = (
  );

my @optkeys = (
  );

unless (@ARGV) { pod2usage(2); };

unless (GetOptions (\%opts, @optkeys)) { pod2usage(2); };


print STDERR "Options:\n";
print STDERR Dumper(\%opts);

use List::MoreUtils qw(first_index);

my @mc_answers = ( 
  ["hard news", '1'],
  ["soft news", '1'],
  ["brève", '1'],
  ["interview paraphrasée", '1'],
  ["interview", '1'],
  ["portrait", '1'],
  ["nécrologie", '1'],
  ["revue de presse", '1'],
  ["éditorial", '1'],
  ["billet", '1'],
  ["critique", '1'],
  ["chronique", '1'],
  ["tribune libre", '1'],
  ["je ne sais pas", '1'],
  );

#### elements ( [ el. name, el. text content ]) to be created and edded to each mc question
my @mc_elements = (
		   [ 'shuffleanswers', '0' ],
		   [ 'single', 'false' ],
		   [ 'answernumbering', 'none' ],
		  );


use XML::LibXML;

# binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');


##### create xml document

my $doc = XML::LibXML::Document->new( '1.0', 'utf-8' );

my $quiz = $doc->createElement ('quiz');

$doc->setDocumentElement($quiz);

my $quest = $doc->createElement('question');
$quest->addChild($doc->createAttribute( type => 'category' ));

my $cat = $doc->createElement('category');
my $cat_text = $doc->createElement('text');

my $text_content = "Annotation en genres";

$cat_text->addChild($doc->createTextNode($text_content));

$cat->addChild($cat_text);
$quest->addChild($cat);

$quiz->addChild($quest);

#### read text file and add questions to xml document

my @FIELD_NAMES = ( 'URL', 'Journal', 'Flux', 'Rubrique', 'Date', 'Texte' );

sub make_question {
  my ($link, $journal, $feed, $cat, $date, $text) = @_;
  my @fields = @_;

  my $quest = $doc->createElement('question');
  $quest->addChild($doc->createAttribute( type => 'description' ));

  my @comp = split(/\//, $link);
  my $base = pop(@comp);
  my $name = $doc->createElement('name');
  my $name_text = $doc->createElement('text');

  $name_text->addChild($doc->createTextNode("$base description"));
  $name->addChild($name_text);
  $quest->addChild($name);

  my $q_text = $doc->createElement('questiontext');
  $q_text->addChild($doc->createAttribute( format => 'html' ));

  my $q_text_text = $doc->createElement('text');

  $fields[0] = "<a href='$fields[0]' target='_blank'>$fields[0]</a>";

  my $cdata_content = '';
  foreach my $i (0..$#fields) {
    my $dt = $FIELD_NAMES[$i];
    my $dd = $fields[$i];
    $cdata_content = join('', $cdata_content, "<dt>$dt</dt><dd>$dd</dd>");
  }

  $cdata_content = "<dl>$cdata_content</dl>";

  $q_text_text->addChild(XML::LibXML::CDATASection->new( $cdata_content ));

  $q_text->addChild($q_text_text);
  
  $quest->addChild($q_text);

  $quiz->addChild($quest);


  return;
}

sub make_mc {
  my ($link) = @_;

  #### multiple choice
  my $quest = $doc->createElement('question');
  $quest->addChild($doc->createAttribute( type => 'multichoice' ));

  my @comp = split(/\//, $link);
  my $base = pop(@comp);
  my $name = $doc->createElement('name');
  my $name_text = $doc->createElement('text');

  $name = $doc->createElement('name');
  $name_text = $doc->createElement('text');
  $name_text->addChild($doc->createTextNode("$base mc"));
  $name->addChild($name_text);
  $quest->addChild($name);

  foreach my $ref (@mc_answers) { 
    my ($ans_text_content, $fraction) = @{ $ref };

    my $answer = $doc->createElement('answer');
    $answer->addChild($doc->createAttribute( fraction => $fraction ));
    my $ans_text = $doc->createElement('text');
    $ans_text->addChild($doc->createTextNode($ans_text_content));
    $answer->addChild($ans_text);

    $quest->addChild($answer);

    foreach my $el_ref (@mc_elements) {
      my ($el_name, $el_txt_content) = @{ $el_ref };
      my $el = $doc->createElement($el_name);
      $el->addChild($doc->createTextNode($el_txt_content));
      $quest->addChild($el);
    }
  }

  $quiz->addChild($quest);

  return;

}

sub make_shortanswer {
  my ($link) = @_;

  ### shortanswer

  $quest = $doc->createElement('question');
  $quest->addChild($doc->createAttribute( type => 'shortanswer' ));

  my @comp = split(/\//, $link);
  my $base = pop(@comp);
  my $name = $doc->createElement('name');
  my $name_text = $doc->createElement('text');

  $name = $doc->createElement('name');
  $name_text = $doc->createElement('text');
  $name_text->addChild($doc->createTextNode("$base shortanswer"));
  $name->addChild($name_text);
  $quest->addChild($name);

    my $qtext_el = $doc->createElement('questiontext');
  $qtext_el->addChild($doc->createAttribute( format => 'html' ));
  my $qtext_el_text = $doc->createElement('text');
  $qtext_el_text->addChild($doc->createTextNode('Critères utilisés ?'));
  $qtext_el->addChild($qtext_el_text);
  $quest->addChild($qtext_el);

  my $answer = $doc->createElement('answer');
  $answer->addChild($doc->createAttribute( fraction => '100' ));
  my $ans_text = $doc->createElement('text');
  $ans_text->addChild($doc->createTextNode('*'));
  $answer->addChild($ans_text);
  $quest->addChild($answer);
  
  $quiz->addChild($quest);

  return;

}

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
      make_question($link, $journal, $feed, $cat, $date, $text);
      make_mc($link);
      make_shortanswer($link);
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
  make_question($link, $journal, $feed, $cat, $date, $text);
  make_mc($link);
  make_shortanswer($link);
  ($link, $journal, $feed, $cat, $date, $text) = (undef, undef, undef, undef, undef, undef);
}

close $fh;

$doc->toFH(\*STDOUT, 1);

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
