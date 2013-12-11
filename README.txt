1) add accession number into the curated table and set status=2

2) ./getAccessions.pl addpending
	Download all files

3)  ./geoloader/geoloader.pl  addPending

1) update curated table with GSE number and set status=2


2) cd modperl; ./getAccesions.pl addPending


3) cd geoLoad; ./geoloader.pl addPending



Experiment parameters are saved in the PEXP table. 

1) perl loadExpPdata.pl save

2) grep gpl3154 pexParms.txt |gpl3154

3) rm pexParms.txt

4) rename 3154 to  pexpParms.txt

5) perl loadExpPdata.pl load it will rerun the experiments which have used GPL3154. 
Now the experiments will be corrected with corrected GPL3154 data.



handle average value and multId



handle average value


ubuntu@domU-12-31-39-16-B6-F6:/home/jgrissom/loadInfo$ grep b4380 G*.txt
GSE20397_new.txt:b4380          0.014
GSE20397_old.txt:b4380          0.013
GSE20397_old.txt:b4380          -0.019
GSE20397_old.txt:b4380          0.043
GSE20397_old.txt:b4380          0.020

ubuntu@domU-12-31-39-16-B6-F6:/home/jgrissom/loadInfo$ grep z5982 G*.txt
GSE20397_new.txt:z5982          0.031
GSE20397_old.txt:z5982          0.043
GSE20397_old.txt:z5982          0.020



http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GPL7445


How to modify the content of GenExpDB Experiments table

1) 
#----------------------------------------------------------------------
Display expinfo when user clicks the "GenExpDB Experiments"
sub expinfo of accessions.pm is called 
#expmID is single experiment id. expid is the accession id
# input: status
# return: none

 

 