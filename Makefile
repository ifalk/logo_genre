### Makefile --- 

## Author: falk@lormoral
## Version: $Id: Makefile,v 0.0 2013/05/06 09:56:29 falk Exp $
## Keywords: 
## X-URL: 

SCRIPT_DIR=bin

LEMONDE_FEEDS=http://www.lemonde.fr/rss/index.html
lemonde_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=lemonde ${LEMONDE_FEEDS} > $@

lemonde_articles.csv: ${SCRIPT_DIR}/get_articles.pl lemonde_rss.pl
	perl $< lemonde_rss.pl > $@

lemonde_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl lemonde_rss.pl 
	perl $< lemonde_rss.pl

LEJDD_FEEDS=http://www.lejdd.fr/rss/index.html
lejdd_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=lejdd ${LEJDD_FEEDS} > $@

lejdd_articles.csv: ${SCRIPT_DIR}/get_articles.pl lejdd_rss.pl
	perl $< lejdd_rss.pl > $@


SLATE_FEEDS=http://www.slate.fr
slate_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=slate ${SLATE_FEEDS} > $@

slate_articles.csv: ${SCRIPT_DIR}/get_articles.pl slate_rss.pl
	perl $< slate_rss.pl > $@ 

slate_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl slate_rss.pl 
	perl $< slate_rss.pl

RUE89_FEEDS=http://www.rue89.com/les-flux-rss-de-rue89
rue89_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=rue89 ${RUE89_FEEDS} > $@

rue89_articles.csv: ${SCRIPT_DIR}/get_articles.pl rue89_rss.pl
	perl $< rue89_rss.pl > $@ 

rue89_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl rue89_rss.pl 
	perl $< rue89_rss.pl

PRESSEUROP_FEEDS=http://www.presseurop.eu/fr/rss
presseurop_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=presseurop ${PRESSEUROP_FEEDS} > $@

presseurop_articles.csv: ${SCRIPT_DIR}/get_articles.pl presseurop_rss.pl
	perl $< presseurop_rss.pl > $@ 

presseurop_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl presseurop_rss.pl 
	perl $< presseurop_rss.pl

LEQUIPE_FEEDS=http://www.lequipe.fr/rss/
lequipe_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl
	perl $< --journal=lequipe ${LEQUIPE_FEEDS} > $@

lequipe_articles.csv: ${SCRIPT_DIR}/get_articles.pl lequipe_rss.pl
	perl $< lequipe_rss.pl > $@ 


lequipe_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl lequipe_rss.pl 
	perl $< lequipe_rss.pl


LALIBRE_FEEDS=http://www.lalibre.be/dossiers/_promo/RSS/
lalibre_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl
	perl $< --journal=lalibre ${LALIBRE_FEEDS} > $@

lalibre_articles.csv: ${SCRIPT_DIR}/get_articles.pl lalibre_rss.pl
	perl $< lalibre_rss.pl > $@ 

lalibre_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_with_paragraphs.pl lalibre_rss.pl 
	perl $< lalibre_rss.pl


DNA_FEEDS=http://www.dna.fr/rss
# Get categories directly from rss xml file
dna_articles.csv: ${SCRIPT_DIR}/get_articles_from_feed.pl 
	perl $< ${DNA_FEEDS} > $@

dna_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_from_feeds_with_paragraphs.pl 
	perl $< ${DNA_FEEDS}

LMD=http://www.monde-diplomatique.fr/rss/
lmd_articles.csv: ${SCRIPT_DIR}/get_articles_from_feed.pl 
	perl $< ${LMD} > $@

lmd_articles_with_paragraphs.html: ${SCRIPT_DIR}/get_articles_from_feeds_with_paragraphs.pl 
	perl $< ${LMD}

### Makefile ends here
