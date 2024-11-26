*****This do creates mortality files to use later. 
**Author : L Mazibuko
**Date started: 13 January 2023
** Date of update : 22 July 2023 
**Reason for update : Decided to use the Excess M Group data files to make sure timelines align.


cd "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work"

clear all
set mem 1000m
set more off,permanently

*------DEFINE GLOBAL MACROS---------------------------------------------------------------*	


*location of do-files and working directory for this analysis
global workingdir = "C:/Users/lusanda.mazibuko/OneDrive - AHRI/Documents/covid excess deaths/lm work"

*location of dataset
global data ="${workingdir}/data"
*location of output folder
global output = "${workingdir}/output"
*location of graphs
global graphs = "${workingdir}/output/graphs"

global yearstart = 2015
global yearend = 2021

cd "${workingdir}" 


*cd "D:\LSHTM_current\Africa Centre\Vukuzazi\do files\Lusanda excess mortality"

********************************************************************************************************************************************

**This file is from the workshop. It is basically created through survival analysis. I will attach the do-file to create it from scratch.  
*use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\Wits Excess Mortality Workshop\ExcessMortality.output-main\ZA031\ZA031_RawCensoredEpisodes_month_age_split.dta" , clear
use "data\RawCensoredEpisodes_month_age_split_KB.dta" , clear
**6488 deaths
tab _d
sort individual exposure_beg exposure_end

bys individualid: gen dup=_n
tab dup
**KB not sure what this is for?
tab died if dup==1
summ dod if dup==1
	count if died~=1 & dod~=.
	count if died==1 & dod==.
**KB - leave this out for now
**current the 'died=1' indicator is on the final record (as the 'event' in survival analsysi) however, the code below will have every record with died=1
*replace died=1 if dod~=.
*summ dod if dup==1
*tab died if dup==1

**KB we don't want to drop these - just censor
*drop if exposure_end>d(31dec2021)
sort individual exposure_beg exposure_end
count if exposure_end>d(31dec2021)
tabstat exposure_beg if exposure_end>d(31dec2021),s(min max) format(%d)
**not sure why these are showing up as after 31st dec
tabstat exposure_end if exposure_end>d(31dec2021),s(min max) format(%d)
replace exposure_end=d(31dec2021) if exposure_end>d(31dec2021)

sort individual exposure_beg exposure_end
**KB not sure how we end up with some before 01jan2015- must be the splits and then recalculation of expsoure end date
count if exposure_end<d(1jan2015)
tabstat enddate if exposure_end<d(1jan2015),s(min max) format(%d)
tabstat exposure_end if exposure_end<d(1jan2015),s(min max) format(%d)
drop if exposure_end<d(1jan2015)

**KB the dup variable no longer counts from 1 since we've dropped the records above
drop dup
sort individual exposure_beg exposure_end
bys individualid: gen dup=_n
**KB these are people who die on first record - not sure why this is important?
tab died if dup==1
*save "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\data\censoreddata.dta", replace

**not sure what this indicator is for -drop and make new one for last observation
drop _l
sort individual exposure_beg exposure_end
by individual: gen _l=1 if _n==_N

**181,565 individuals with 6588 deaths
unique individualid
tab died if _l==1

save "data\censoreddata.dta", replace

**KB - get Vukuzazi information
use "D:\LSHTM_data\Africa Centre\Vukuzazi\Vukuzazi_mortality_analysis_v3.dta" , clear
*use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\Vukuzazi datasets\Vukuzazi_mortality_analysis_v3.dta", clear 
	rename _all, lower
**drop all unnecessary variables - for now I am dropping alot of them
		drop ageatrecruitment ageatrecruitmentcat ageatenrolment ageatenrolmentcat episode* startdate enddate resident currsmoker-eversmokeddaily smokeamount smokeamountcat quitsmokingmonths-numberalcoholuntaxed drinkamount-artinitiationyear artdefault artdefaulttimes cd4lymphab-cd8lymphpercent receivedtbinjections numbertbtxever- othersymptoms referredforsputum-inducedtbsputumhome genexpert liquidculture  rifampicin-kanamycin50 bpfirstsystolic-bpforthdiastolic bpmeasuredever-highbpherbalcurr bpcontrol-bpherbalrx bsugarmeasuredever-highbsugarherbalcurr dmrx2wk-highcholesttx2wks highcholestconsulthealer-fubpdiagnosis age smoking_advice entrydate exitdate consent_rdt studyoutcome hivaware hivcontrol hivonartsupp hivincare tbsymptom totaltbsymptom cxrscore hba1cpercentcat
	  
save vuk$, replace
	


use "data/censoreddata.dta",clear
tabstat exposure_beg exposure_end, s(min max) format (%td) // this is fine 
**My goal is to merge this data with Vukuzazi so I need to rename the ID 
ren individualid iintid
tabstat	dod, s(min	max) format (%td) // these go as far as 22 Oct 2022 KB-I get 02/apr/2022
**but deaths that are 'events' are all by 31dec2021
tabstat	dod if died==1, s(min	max) format (%td) 
**the ones who died after 2021 are not recorded as deaths
tabstat	dod if _l==1, s(min	max) format (%td) by(died)
strate, output(all24,replace) nolist
strate sex , output(sex24,replace) nolist
strate age_group , output(agegrp24,replace) nolist

***merging in vukuzazi data 
*merge m:1 iintid using "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\code\vz_deaths.dta"
merge m:1 iintid using "vuk$"
**5 in Vuk but not in this main dataset
drop if _merge==2
	sort iintid exposure_beg exposure_end _t0
**after call with mark 26 October - restrict to Vukuzazi participants only
	keep if _m==3
	drop _m motherid fatherid individualid days memberships gap episode*
	sort iintid  exposure_beg exposure_end
	
save "data\vz_censoreddata.dta", replace 

**KB - here i'm doing it a bit diferently - although agreed with Mark now that we wont' do this bit
*use "D:\LSHTM_data\Africa Centre\ACDIS\Stata\RD03-99 ACDIS WGH ALL.dta" , clear
	use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\AHRI Biostats\RD03-99 ACDIS WGH ALL.dta", clear 
	gen sex=2
	append using "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\AHRI Biostats\RD04-99 ACDIS MGH ALL.dta" 
	replace sex=1 if sex==.
	tabstat VisitDate, s(min max) format(%td) by(sex)
	rename _all, lower
**keep the variables of interest
	keep iintid visitdate highbp* highbsugar* tb* generalhealth
	gen year=year(visitdate)

gen bp=.
replace bp=0 if highbplast12m==2| highbpcurrtmt==2| highbptxever==2| highbptx12m==2
replace bp=1 if highbplast12m==1| highbpcurrtmt==1| highbptxever==1| highbptx12m==1
replace bp=2 if bp==.
label def bp 0"No" 1"Yes" 2"Unknown"
label val bp bp
tab bp

replace generalhealth=99 if generalhealth>6

gen hyperglycemia=.
replace hyperglycemia=0 if highbsugarlast12m==2| highbsugarcurrtmt==2| highbsugartxever==2| highbsugartx12m==2
replace hyperglycemia=1 if highbsugarlast12m==1| highbsugarcurrtmt==1| highbsugartxever==1| highbsugartx12m==1
replace hyperglycemia=2 if hyperglycemia==.
label def hyperglycemia 0"No" 1"Yes" 2"Unknown"
label val hyperglycemia hyperglycemia
tab hypergly

gen tb=.
replace tb=0 if tblast12m==2|(tbcurrtmt==2 & tbtxever==2)| tbtxever==2| tbtx12m==2
replace tb=1 if tbtxever==1
replace tb=2 if tblast12m==1| tbtx12m==1| tbcurrtmt==1
replace tb=3 if tb==.
label def tb 0"No" 1"Previous TB" 2"Current TB" 3"Unknown"
label val tb tb
tab tb

	tab year if bp==2 & hypergly==2 & tb==3
	drop if bp==2 & hypergly==2 & tb==3
**for each person, find out min/max years for which there are data
	sort iintid visitdate
	by iintid:egen minyear=min(year)
	by iintid:egen maxyear=max(year)
	by iintid:gen _f=1 if _n==1
/*not doing this now - try another approach - min/max date for each condition	
**for all who have data from 2015+, can delete the earlier years	
	tab maxyear if _f==1
	drop if maxyear>=2015 & year<2015
*/	
	
**people seem to change their answers alot 	
**get the min/max date for each condition (when neg or pos)
		gen _pbp=visitdate if bp==1
		gen _pdm=visitdate if hypergly==1
**put current/past tb together		
		gen _ptb=visitdate if tb==1|tb==2		
	
		gen _nbp=visitdate if bp==0
		gen _ndm=visitdate if hypergly==0
		gen _ntb=visitdate if tb==0	

foreach var in bp dm tb {		
	by iintid:egen dt_first_neg_`var'=min(_n`var')
	by iintid:egen dt_last_neg_`var'=max(_n`var')
	by iintid:egen dt_first_pos_`var'=min(_p`var')		
	by iintid:egen dt_last_pos_`var'=max(_p`var')		
}		
	format dt_first* dt_last* %td
	
	keep iintid dt* min max
	
	*save "all indiv health survey.dta", replace
save "data/indiv_health_all.dta", replace


**KB: I will do this differently-get dates of last neg & first pos tests
*use "D:\LSHTM_data\Africa Centre\ACDIS\Stata\RD05-99 ACDIS HIV All.dta" ,clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\AHRI Biostats\RD05-99 ACDIS HIV All.dta", clear 
	tabstat VisitDate, s(min max) format(%td) 
	rename _all, lower
	tab hivresult
	drop if hivresult>1
	gen _nd=visitdate if hivresult==0
	gen _pd=visitdate if hivresult==1
	sort iintid visitdate
	by iintid:egen dt_first_neg=min(_nd)
	by iintid:egen dt_last_neg=max(_nd)
	by iintid:egen dt_first_pos=min(_pd)
		format dt* %td
	keep iintid dt*
	duplicates drop
	unique iintid
save hiv$, replace	


**KB merge in HIV serosurvey info
use "data/censoreddata.dta",clear
**need to keep the variable name 'individual' since it's in the stset
	stset 
	gen iintid=individualid
	merge m:1 iintid using hiv$
	drop if _m==2
	drop _m
**quick checks	
**check whether any HIV dates are before DOB
	count if dt_first_neg<dob & dob~=.
	count if dt_first_pos<dob & dob~=.

**pos before neg - these are not valid 
	unique iintid if dt_first_pos<dt_last_neg & dt_last_neg~=.
	gen valid=1
		replace valid=0 if dt_first_pos<=dt_last_neg & dt_last_neg~=.
	unique iintid if valid==0	
	tab valid	
	
**midpoint seroconversion just for convenience (dont' want to impute dates)	
	gen midpointdate=dt_last_neg+((dt_first_pos-dt_last_neg)/2) if dt_first_pos~=. & dt_last_neg~=. & valid==1
	format midpointdate %d
	
**now split on dates of first & last neg, and first positive	
**for those with no positive test
	stsplit split_on_lastneg if dt_last_neg < . & dt_first_pos==., after(dt_last_neg) at(0)
**for those with no negative test	
	stsplit split_on_pos if dt_first_pos < .  & dt_last_neg==., after(dt_first_pos) at(0)
**for seroconversion
	stsplit split_on_sero if midpointdate < . , after(midpointdate) at(0)
	
**HIV status 
	label define hivstatus_lbl 	1 "Negative" 2 "Positive" 3 "Pre-positive" 4 "Post-negative" 5 "Unknown" , modify
	
	gen hivstatus=.	
	label values hivstatus hivstatus_lbl	
**negative
	replace hivstatus=1 if split_on_lastneg==-1 & valid==1 
**allow 2 years post negative if no positiv test	
		replace hivstatus=1 if split_on_lastneg==0 & split_on_pos==. & (exposure_end-dt_last_neg)<731 & valid==1 
**negative up to midpoint	
		replace hivstatus=1 if split_on_sero==-1 & valid==1
	
**positive	
	replace hivstatus=2 if split_on_pos==0 & valid==1
		replace hivstatus=2 if split_on_sero==0 & valid==1
	
**pre-pos: before first positive test, but no neg tests	
	replace hivstatus=3 if split_on_pos==-1 & split_on_lastneg==. & valid==1
**post-neg: after last negative test, but no pos tests	
	replace hivstatus=4 if split_on_lastneg==0 & split_on_pos==. & (exposure_end-dt_last_neg)>=731 & valid==1
	
**no test results - unknown	
	replace hivstatus=5 if split_on_lastneg==. & split_on_pos==. & split_on_sero==.
**also unknown if pos test before neg	
	replace hivstatus=5 if valid==0

**should be none with missing status
		tab hivstatus,m
		
save "data\censored_hivstatus.dta", replace		
	

****END. Continue on Predictions script****




**===================================================================================
erase hiv$.dta
erase vuk$.dta
