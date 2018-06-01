/* create library */

libname file 'X:\my_data_analysis\20170620\';
proc import out= file.complete 
 	datafile= "X:\my_data_analysis\20170620\20170620_sesqui.csv" 
            dbms=csv replace;
     getnames=yes;
     datarow=2;
run;

/* select few rows and a columns only*/
data file_name; 
set file.complete (keep = ColName1  ColName2 ColName3);
run;

data data_subset; 
set file.complete (keep = ColName1  ColName2 ColName3);
if ColName1 in ("RowName1","RowName2", "RowName3");
run;

/* create csv file */
proc export data =data_subset
outfile = "X:data_subset.csv"
			dbms = csv replace;
	putnames = yes;
run;

/* test covariance structure to figureout best fit
change typ=un ar(1) cs */

ods rtf file = "X:results\result_file.rtf"; 
proc mixed data=file_name covtest ;
class treatment replication time;
model total = treatment time treatment*time/residual;
repeated time/subject=Replication(treatment) type=un;
ods output FitStatistics=FitUN (rename=(value=UN))
Dimentions=ParmUN(rename=(value=NumUN));
run;

ods rtf file = "X:results\result_file.rtf"; 
proc mixed data=file_name covtest ;
class treatment replication time;
model total = treatment time treatment*time/residual;
repeated time/subject=Replication(treatment) type=ar(1);
ods output FitStatistics=FitAR1 (rename=(value=AR1))
Dimentions=ParmAR1(rename=(value=NumAR1));
run;

ods rtf file = "X:results\result_file.rtf_covar"; 
proc mixed data=file_name covtest ;
class treatment replication time;
model total = treatment time treatment*time/residual;
repeated time/subject=Replication(treatment) type=cs;
ods output FitStatistics=FitCS (rename=(value=CS))
Dimentions=ParmCS(rename=(value=NumCS));
run;

data all;
merge FItUN FitCS FitAR1;
run;

proc print data=all label noobs;
run;

proc print;
run;
ods rtf close;

/* select covariance str based on lowest AIC and BIC value
drop repeated statement of the best covariance str has p-value greater than 0.20 */ 

ods rtf file = "X:results\result_file_lsmean.rtf"
proc mixed data=file_name;
class treatment replication time;
model total = treatment time treatment*time /residual;;
repeated time/subject=Replication(treatment) type=ar(1);
lsmeans treatment*time/ adjust=tukey pdiff slice=Time_after_exposure; 
ods output diffs = ppp lsmeans = mmm;
ods listing exclude diffs lsmeans;
run;

/* assgn different letters to significanlty different treatments */ 
%include "X:pdmix800.sas";
%pdmix800(ppp,mmm,alpha=0.05, sort=no);
run;

proc print;
run;
ods rtf close;

/* 
if interaction term is non-significant, remove interaction term from 'model' statement.
use 'lsmeans' statement only if
- one of the main effects has more than2 levels
- either main effects or their interaction is significant
*/ 
