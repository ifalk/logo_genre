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

RUE89_FEEDS=http://www.rue89.com/les-flux-rss-de-rue89
rue89_rss.pl: ${SCRIPT_DIR}/get_feeds_by_column.pl 
	perl $< --journal=rue89 ${RUE89_FEEDS} > $@

rue89_articles.csv: ${SCRIPT_DIR}/get_articles.pl rue89_rss.pl
	perl $< rue89_rss.pl > $@ 


PRESSEUROP_FEEDS=http://www.presseurop.eu/fr/rss
presseurop_rss.csv: ${SCRIPT_DIR}/get_presseurop_feeds_by_column.pl 
	perl $< ${PRESSEUROP_FEEDS} > $@


DNA_FEEDS=http://www.dna.fr/rss
# Get categories directly from rss xml file
dna_articles.csv: ${SCRIPT_DIR}/get_articles_from_feed.pl 
	perl $< ${DNA_FEEDS} > $@

LMD=http://www.monde-diplomatique.fr/rss/
lmd_articles.csv: ${SCRIPT_DIR}/get_articles_from_feed.pl 
	perl $< ${LMD} > $@

### Makefile ends here
