### Makefile --- 

## Author: falk@lormoral
## Version: $Id: Makefile,v 0.0 2013/05/06 09:56:29 falk Exp $
## Keywords: 
## X-URL: 

SCRIPT_DIR=bin

LEMONDE_FEEDS=http://www.lemonde.fr/rss/index.html
lemonde_rss.pl: ${SCRIPT_DIR}/get_lemonde_feeds_by_column.pl 
	perl $< ${LEMONDE_FEEDS} > $@

lemonde_articles.csv: ${SCRIPT_DIR}/get_articles.pl lemonde_rss.pl
	perl $< lemonde_rss.pl > $@

LEJDD_FEEDS=http://www.lejdd.fr/rss/index.html
lejdd_rss.csv: ${SCRIPT_DIR}/get_lejdd_feeds_by_column.pl 
	perl $< ${LEJDD_FEEDS} > $@

SLATE_FEEDS=http://www.slate.fr
slate_rss.csv: ${SCRIPT_DIR}/get_slate_feeds_by_column.pl 
	perl $< ${SLATE_FEEDS} > $@

RUE89_FEEDS=http://www.rue89.com/les-flux-rss-de-rue89
rue89_rss.csv: ${SCRIPT_DIR}/get_rue89_feeds_by_column.pl 
	perl $< ${RUE89_FEEDS} > $@

PRESSEUROP_FEEDS=http://www.presseurop.eu/fr/rss
presseurop_rss.csv: ${SCRIPT_DIR}/get_presseurop_feeds_by_column.pl 
	perl $< ${PRESSEUROP_FEEDS} > $@


DNA_FEEDS=http://www.dna.fr/rss
# Get categories directly from rss xml file
# dna_rss.csv: ${SCRIPT_DIR}/get_dna_feeds_by_column.pl 
# 	perl $< ${DNA_FEEDS} > $@

LMD=http://www.monde-diplomatique.fr/rss/
# Get categories directly from rss xml file
# dna_rss.csv: ${SCRIPT_DIR}/get_dna_feeds_by_column.pl 
# 	perl $< ${DNA_FEEDS} > $@



### Makefile ends here
