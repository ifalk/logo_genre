### Makefile --- 

## Author: falk@lormoral
## Version: $Id: Makefile,v 0.0 2013/03/12 08:24:02 falk Exp $
## Keywords: 
## X-URL: 

LOGO_DIR=/home/falk/Logoscope/VC/genre
SCRIPT_DIR=${LOGO_DIR}/bin


lemonde_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/lemonde_articles.csv
	perl $< ${LOGO_DIR}/lemonde_articles.csv > $@

lejdd_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/lejdd_articles.csv
	perl $< ${LOGO_DIR}/lejdd_articles.csv > $@

dna_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/dna_articles.csv
	perl $< ${LOGO_DIR}/dna_articles.csv > $@

lmd_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/lmd_articles.csv
	perl $< ${LOGO_DIR}/lmd_articles.csv > $@

slate_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/slate_articles.csv
	perl $< ${LOGO_DIR}/slate_articles.csv > $@

rue89_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/rue89_articles.csv
	perl $< ${LOGO_DIR}/rue89_articles.csv > $@

presseurop_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/presseurop_articles.csv
	perl $< ${LOGO_DIR}/presseurop_articles.csv > $@

lequipe_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/lequipe_articles.csv
	perl $< ${LOGO_DIR}/lequipe_articles.csv > $@

lalibre_quest.xml: ${SCRIPT_DIR}/make_moodle_quest.pl ${LOGO_DIR}/lalibre_articles.csv
	perl $< ${LOGO_DIR}/lalibre_articles.csv > $@


### Makefile ends here
