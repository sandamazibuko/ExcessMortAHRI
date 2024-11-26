***************************************************************************************
*-------------------------------------------------------------------------------------*
********  				 MORTALITY ANALYSIS                          ********
*-------------------------------------------------------------------------------------*
***************************************************************************************

/*

DESCRIPTION
This do-file runs other do files for excess mortality analysis
*/
clear all
set mem 1000m
set more off,permanently

*------DEFINE GLOBAL MACROS---------------------------------------------------------------*	

/*
*location of do-files and working directory for this analysis
global workingdir = "C:/Users/lusanda.mazibuko/OneDrive - AHRI/Documents/covid excess deaths/Wits Excess Mortality Workshop"

*location of dataset
global data ="${workingdir}/ExcessMortality.output-main/ZA031"
*location of output folder
global output = "${workingdir}/output"
*location of graphs
global graphs = "${workingdir}/graphs"

global yearstart = 2015
global yearend = 2021

*------------------------------------------------------------------------------------*		            	                  

cd "${workingdir}" 

global sitename="ZA031"
*/

cd "D:\LSHTM_current\Africa Centre\Vukuzazi\do files\Lusanda excess mortality"
/*
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				READ RAW DATA							 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
import delimited "${data}/${sitename}_RawCensoredEpisodes.csv", varnames(1) encoding(ISO-8859-1)clear
foreach var of varlist dob  startdate  enddate {
	gen `var'2 = date(`var', "YMD")
	format `var'2 %td
	drop `var'
	rename `var'2 `var'
}
gen dod = enddate if endevent == "DTH"
gen died = endevent == "DTH"

label define sex_lbl 1 "male" 2 "female" 
label values sex sex_lbl

* CHECK AND DROP EPISODES WITH UNKNOWN SEX
tab sex
count if ! inlist(sex,1,2)
drop if ! inlist(sex,1,2)

save "${data}/${sitename}_RawCensoredEpisodes", replace


use "${data}/${sitename}_RawCensoredEpisodes", clear
* DROP EPISODES WITH NEGATIVE DURATION
count if startdate>enddate
drop if startdate>enddate

* CHECK NUMBER OF EPISODES WITH ZERO DURATION
count if startdate==enddate
***************************************************************************************
*-------------------------------------------------------------------------------------*
********  				 MORTALITY ANALYSIS                          ********
*-------------------------------------------------------------------------------------*
***************************************************************************************

/*

DESCRIPTION
This do-file runs other do files for excess mortality analysis
/
clear all
set mem 1000m
set more off,permanently

*------DEFINE GLOBAL MACROS---------------------------------------------------------------*	


*location of do-files and working directory for this analysis
global workingdir = "~/OneDrive - University of Witwatersrand/DataDistribution/HDSSExcessMortality/Analysis_Workshop"

*location of dataset
global data ="${workingdir}/data/AnalysisReady"
*location of output folder
global output = "${workingdir}/output"
*location of graphs
global graphs = "${workingdir}/graphs"

global yearstart = 2015
global yearend = 2021

*------------------------------------------------------------------------------------*		            	                  

cd "${workingdir}" 

global sitename="ZA011"
*/	
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				READ RAW DATA							 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
import delimited "${data}/${sitename}_RawCensoredEpisodes.csv", varnames(1) encoding(ISO-8859-1)clear
foreach var of varlist dob  startdate  enddate {
	gen `var'2 = date(`var', "YMD")
	format `var'2 %td
	drop `var'
	rename `var'2 `var'
}
gen dod = enddate if endevent == "DTH"
gen died = endevent == "DTH"

label define sex_lbl 1 "male" 2 "female" 
label values sex sex_lbl

* CHECK AND DROP EPISODES WITH UNKNOWN SEX
tab sex
count if ! inlist(sex,1,2)
drop if ! inlist(sex,1,2)

* DROP EPISODES WITH NEGATIVE DURATION
count if startdate>enddate
drop if startdate>enddate

* CHECK NUMBER OF EPISODES WITH ZERO DURATION
count if startdate==enddate


* GIVE 1/5 OF A DAY TO INDIVIDUALS WITH STARTDATE = ENDDATE 
* SO THAT THEY ARE INCLUDED IN THE SURVIVAL TIME CALCULATIONS
replace enddate = enddate+0.2 if startdate == enddate
save "${data}/${sitename}_RawCensoredEpisodes", replace

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				STSET WITH DEATH AS THE FAILURE						 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
use "${data}/${sitename}_RawCensoredEpisodes", clear
stset enddate, id(individualid) failure(died) time0(startdate) origin(dob) scale(365.25)
count if _t0 >= _t
drop if _t0 >= _t
save "${data}/${sitename}_RawCensoredEpisodes_st_ready", replace
*/
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				STSET WITH CALENDAR TIME AS THE TIMESCALE					 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
/*
-stset- the data in a different way, so that _t0 and _t are counting from a date in the calendar.
For that use -enter()- rather than -origin()-, because this counts all times from 0, which is 
10jan1960 is Stata's date format.
*/
**KB - this seems to cause a problem in that people who have >1 episode have only first episode kept?
**need the time0 in order for them to remain in dataset?
**eg. look at ID 23 - they were in PIP from 1jan2000 until 31dec2021, but have 9 episodes
**seens that only the episode up to 02aug2017 is kept (first episode includes 2015 date)
*use "${data}/${sitename}_RawCensoredEpisodes", clear

*use "data/RawCensoredEpisodes_st_ready", clear

use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\For Kathy B\data\RawCensoredEpisodes_st_ready.dta"
stset enddate, id(individualid) fail(died) enter(startdate) exit(enddate)  
count if _t0 >= _t
sort individual startdate enddate
**these all get dropped b/c you don't allow them to come back in again (N=298,050)

**need to remove the exit option - 
**also use time0 to allow gaps in the analysis (so if there is a gap between enddate on one episode
**and startdate on next (for the same ID)
stset enddate, id(individualid) fail(died) enter(startdate) time0(startdate) 
count if _t0 >= _t
**should now be none that get dropped, and are 24,501 deaths
drop if _t0 >= _t
*save "${data}/${sitename}_RawCensoredEpisodes_calendaer_st_ready", replace

**However, this keeps the gaps in the analysis (if someone outmigrates & then returns)
**I think we can count continuous person-years for mortality
save "data\RawCensoredEpisodes_calendaer_st_ready_KB", replace

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				COMPUTE AND PLOT PERSON YEARS AND NUMBER OF DEATHS				**
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S1_PersonYearsAndDeaths".do


*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				CREATE POPULATION PYRAMIDS									 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S2_create_pop_pyramids".do

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				MORTALITY RATES BY AGE, SEX, YEAR								 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S3_MortalityRates".do

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				LIFE EXPECTANCY ESTIMATES								 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S4_LE_Estimates".do
do "${workingdir}/do/S4_LE_EstimatesV2".do

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				LIFE EXPECTANCY DIFFERENCES DECOMPOSITION								 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S5_Decompose_LE_Differences".do

*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
**				MORTALITY RATES BY MONTH								 **
*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
do "${workingdir}/do/S6_MonthlyMortalityRates".do



