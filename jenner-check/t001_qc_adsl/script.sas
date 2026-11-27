***records mapped directly from dm domain;


		*creating empty data in the rawdata and work lib;
/*proc datasets lib= rawdata kill;
run;
quit;

proc datasets lib = work kill;
run;
quit;*/

				***sorting dm dataset;
proc sort data=rawdata.dm out=dm1(keep=SEX STUDYID USUBJID SUBJID SITEID AGE AGEU RACE RFSTDTC RFENDTC COUNTRY ARM ARMCD);
by usubjid;
run;

				**records derived from dm domain;
data dm1;
	length STUDYID SUBJID REGION SITEID $20 Age SEXN 8. TRT01P $50 Country $8;
	set dm1;
	if sex="M" then SEXN=1;
	else if sex="F" then SEXN=2;
	TRT01P=ARM;
	**deriving region variable using the country variable;
	if country in("CAN","USA") then REGION="NORTH AMERICA"; 
	else if country in ("AUT","BEL","DNK","ITA","NLD","NOR","SWE","FRA","ISR", "DEU", "ESP", "GBR") then REGION="WESTERN EUROPE"; 
	else if country in ("BLR","BGR","HUN","POL","ROU","RUS","SVK","UKR","TUR", "HRV", "SCG") then REGION="EASTERN EUROPE"; 
	else if country in ("AUS","CHN","HKG","IND","MYS","SGP","TWN","THA") then REGION="ASIA"; 
	else if country in ("ARG","CHL","COL","MEX","PER") then REGION="LATIN AMERICA"; 
	else if country in ("ZAF") then REGION = "AFRICA";
	*** TRT01PN using arm variable;
	if arm="PLACEBO" then TRT01PN=1;
	else if arm="CYT001 3 MG" then TRT01PN=2;
	else if arm="CYT001 10 MG" then TRT01PN=3;
	*** TRT01AN using arm variable;
	if arm="PLACEBO" then TRT01AN=1;
	else if arm="CYT001 3 MG" then TRT01AN=3;
	else if arm="CYT001 10 MG" then TRT01AN=2; 
	ARFSTDT= input(RFSTDTC, yymmdd10.);
	format ARFSTDT date9.;
run; 

proc sort data=dm1;
by usubjid;
run;


***sorting by usubjid and keeping usbjid and the variables needed to derive the adsl variables;
proc sort data=rawdata.ds out=ds1(keep= usubjid DSTERM DSSTDTC DSSCAT DSDECOD DSCAT);
by usubjid;
run;


*variables derived from ds;
data ds1x;
	length EOS $50 EOSCODE $50 EOSFL $1;
	set ds1;
	by usubjid;
			****creating a numeric var****;
	*first_id = first.usubjid;
			****deriving randomization date****;
	if DSDECOD="RANDOMIZED" and length(DSSTDTC) = 10 then RANDDT= input(DSSTDTC, yymmdd10.);
	else RANDDT=.;
	if RANDDT ne . then RANDFL="Y";
	*else RANDFL= "N";
			****deriving DTHFL variable****;
	if DSDECOD="DEATH" and DSCAT="DISPOSITION EVENT" then DTHFL="Y";
			****deriving DTHDT variable, possible issue in the rsd****;
	if DSDECOD="DEATH" and DSCAT="DISPOSITION EVENT" and length(DSSTDTC) = 10 then DTHDT= input(DSSTDTC, yymmdd10.);
	else DTHDT=.;
			****deriving EOSFL variable****;
	if DSSCAT="END OF STUDY" then EOSFL="Y";
	else EOSFL="N";
			****deriving EOSDT variable****;

	if DSDECOD="COMPLETED" and DSSCAT="END OF STUDY" and length(DSSTDTC) = 10 then EOSDT= input(DSSTDTC, yymmdd10.);
	else EOSDT=.;
		****deriving EOS variable****;
	if dscat = "DISPOSITION EVENT" and dsdecod = "COMPLETED" then EOS= "COMPLETED";
	else if dscat = "DISPOSITION EVENT" then EOS = dsterm;
		****deriving EOSCODE variable****;
	if dscat = "DISPOSITION EVENT" and dsdecod = "COMPLETED" then EOSCODE = "COMPLETED";
	else if dscat = "DISPOSITION EVENT" then EOSCODE = DSDECOD;
		****where length(DSSTDTC) ne 10****;
	format DTHDT EOSDT RANDDT date9.;
	drop DSTERM DSDECOD DSCAT;
run;

proc sort data=ds1x nodupkey;
by usubjid;
run;

				*working on variables derived from ex;

proc sort data=rawdata.ex out=ex1(keep= Usubjid EXTRT EXSTDTC EXENDTC rename=(EXTRT=ACTARM));
by usubjid;
run;

data ex1x;
	length TRT01A $50. ACTARMCD $20;
	set ex1;
	by usubjid;
			****creating first_id =1 if first obs in the by group and 0 if  not first obs in the by group****;
	first_id = first.usubjid;
	last_id = last.usubjid;
	if ACTARM = "PLACEBO" then ACTARMCD = "PLAC";
	else if ACTARM = "CYT001 3 MG" then ACTARMCD = "CYT0013";
	else if ACTARM = "CYT001 10 MG" then ACTARMCD = "CYT0010";
	TRT01A= ACTARM;
run;


		*TRT01SDT TRT01EDT variables ;
data ex2;
	set ex1x;
	if first_id ne 0 then TRTSDT=input(EXSTDTC, yymmdd10.);
	if length(EXENDTC) = 10 and last_id = 1 then do;
	TRTEDT=input(EXENDTC, ??yymmdd10.);
	end;
	format TRTSDT TRTEDT date9.;
run;

		*TRT01SDT TRT01EDT variables;
data ex3;
	set ex2;
	TRT01SDT=TRTSDT;
	TRT01EDT=TRTEDT;
	format TRT01SDT TRT01EDT date9.;
	drop EXENDTC;
run;

proc sort data=ex3 nodupkey;
by usubjid;
run;

		 **variables derived from vs;
		****sorting vs dataset****;
proc sort data=rawdata.vs out=vs1(keep= usubjid VSSTRESN VSTESTCD VSBLFL);
by usubjid;
run;
		****creating WGTB and HGTB from VSSTRESSN****;
data vs2;
set vs1;
if VSTESTCD = "WEIGHT" and VSBLFL = "Y" then WGTB=VSSTRESN;
if VSTESTCD = "HEIGHT" and VSBLFL = "Y" then  HGTB=VSSTRESN;
run;


		****removing missing WGTB and droping HGTB****;
data vs1w;
set vs2;
where WGTB ne .;
drop HGTB;
run;

		****removing missing HGTB and droping WGTB****;
data vs1h;
set vs2;
where HGTB ne .;
drop WGTB;
run;

		****merging the two datasets: vs1w and vs1h;
data vs3;
merge vs1w vs1h;
by usubjid;
drop VSSTRESN VSTESTCD VSBLFL;
**convert Height to meter;
Height = HGTB/100;
Weight = WGTB;
run;
		****calculating BMI****;
data vs1x;
set vs3;
BMI= Weight/(Height**2);
drop Weight Height;
run;

		****sorting sv dataset;
proc sort data=rawdata.sv out=sv1(keep= usubjid SVSTDTC);
by usubjid;
run;

		****min svstdtc in the by variable to form AP01SDT****;
data sv2;
set sv1;
by usubjid;
first_id = first.usubjid;
if first_id =1 then  AP01SDT= input(svstdtc, yymmdd10.);
format AP01SDT date9.;
drop SVSTDTC;
run;

proc sort data=sv2 nodupkey;
by usubjid;
run;


data adslx;
merge dm1(in=a) sv2(in=b) ex3(in=c) ds1x(in=d) vs1x(in=e);
by usubjid;
if a;
run;




data adslx1;
length ARM_ ACTARM_ $50. USUBJID_ $20;
set adslx;
ARM_ = ARM;
USUBJID_ = USUBJID;
ACTARM_ = ACTARM;
if RFENDTC ne " " and length(RFENDTC) = 10 then  ARFENDT = input(RFENDTC, yymmdd10.);
*else if RFENDTC ne " " and length(RFENDTC) = 7 then  ARFENDT = input(compress(RFENDTC, "-"), yymmn6.);
else if DSSCAT = "END OF STUDY" then ARFENDT = input(DSSTDTC, yymmdd10.);
if RANDDT ne . and EXSTDTC ne " " then SAFFL = "Y";
if TRT01EDT ne . then AP01EDT = TRT01EDT + 28;
if ARFENDT ne . and ARFSTDT ne . then STYDURD = ARFENDT - ARFSTDT + 1;
format ARFENDT AP01EDT date9.;
drop RFENDTC last_id first_id RFENDTC EXSTDTC DSSTDTC DSSCAT USUBJID ACTARM ARM RFSTDTC;
run;

data adslx2(rename=(ARM_ = ARM USUBJID_ = USUBJID ACTARM_ = ACTARM));
set adslx1;
run;
