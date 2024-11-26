****
*****do file to try to replicate analysis of Bianca
**do this now for PIP data (can only do for HIV)

cd "D:\LSHTM_current\Africa Centre\Vukuzazi\do files\Lusanda excess mortality"
cd "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\"
clear all
set mem 1000m
set more off,permanently


********************************************************************************************************************************************

**PIP data with HIV from serosurvey - created by "Data creation do-file - 22 July 2023_KB.do"

use "data\censored_hivstatus.dta",clear 
	tab hivstatus,m
**drop if <15
		drop if age_yrs<15
**prepare for collpase
	unique year month iintid
**we need to count number of people in each month (denominator) & number of deaths
**denominator is population rather than time
	sort iintid year month _t0 _t
	by iintid  year month:gen pop=1 if _n==1
**should be 7760179 (as in 'unique' command above)
	tab pop
**this is so we only count people once per month - they will have 2 records in a month if their age changes 	
	tab age_group10
	gen age_cat=age_yrs
	recode age_cat min/29=1 30/49=2 50/max=3
	label def agecat 1"<30" 2"30-49" 3"50=", modify
	label val age_cat age_cat
	tabstat age_yrs,s(min max n) by(age_cat)

save pip$, replace	

**first use all HIV categories
use pip$,clear
	collapse (sum) totpop=pop died=_d, by(year month age_cat sex hivstatus )
save Phiv$, replace

**now just use pos/neg
use pip$,clear
	drop if hivstatus>2
	tab hivstatus
	recode hivstatus 1=0 2=1
	label val hivstatus lblYesNo
	collapse (sum) totpop=pop died=_d, by(year month age_cat sex hivstatus )	
save Phiv2$, replace
	
*** Table 1 
use pip$,clear
	drop if hivstatus>2
	tab hivstatus
	recode hivstatus 1=0 2=1
	label val hivstatus lblYesNo

bys individualid: gen lastob=_n==_N
tab hivstatus if lastob==1
strate hivstatus, output(hivstatus,replace) nolist

use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\hivstatus.dta" , clear
rename _D Deaths
rename _Y PersonTime
rename _Rate Mortality
rename _Lower lb
rename _Upper up
gen PersonYears=PersonTime/365.25 // convert persondays to personyears
egen TotD = sum(Deaths)
gen mx_1000 = (Deaths/PersonY)*1000
gen lb_mx_1000 = lb *1000 *365.25
gen ub_mx_1000 = up*1000 *365.25
egen TotPY = sum(PersonY)
order hivstat Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000

use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\all24.dta" , clear
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\sex24.dta", clear
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\agegrp24.dta", clear 
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\ses24.dta", clear 
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order asset Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear

use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\tbtxt.dta", clear
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
rename _D Deaths
egen TotD = sum(Deaths)
gen mx_1000 = (Deaths/PersonY)*1000
order tbcat Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\bmicat.dta", clear 
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\dmdiag.dta"
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
clear
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\htndiag.dta"
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000

use "pip2$", clear
strate assetin, output(ses24,replace) nolist
use "C:\Users\lusanda.mazibuko\OneDrive - AHRI\Documents\covid excess deaths\lm work\ses24.dta" 
rename _D Deaths
renam _Y PersonDays
renam _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
egen TotPY = sum(PersonY)
gen mx_1000 = (Deaths/PersonY)*1000
order asseti Deaths PersonYears mx_1000 lb_mx_1000 ub_mx_1000
br
	
	
	


**=======================================================
**HIV - all categories
**=======================================================

use Phiv$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
**this creates 3 sin/cos pairs per year ('harmonics' referred to in Bhaskaran paper)
fourier degrees, n(3)
su sin* cos*
**check 
egen time=group(year month)
twoway (line sin_1 time) (line  cos_1 time, lcolor(red))
**looks very jagged - probably b/c this is per month rather than week
twoway (line sin_1 time,lcolor(blue)) (line  sin_2 time, lcolor(red)) (line  sin_3 time, lcolor(green))

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died year sin* cos* ib3.age i.sex i.pandemic, family(nb ml) link(log) exposure(totpop) eform 
predict fv1
**observed vs fitted
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(1"Jan2015" 7 "Jul2015" 13"Jan2016" 19"Jul2016" 25"Jan2017" 31"Jul2017" 37"Jan2018" 43"Jul2018" 49"Jan2019" 55"Jul2019" 61"Jan2020" 67"Jul2020"  73"Jan2021" 79"Jul2021", angle(45) labsize(vsmall)) 


glm died i.pandemic##i.hiv year sin* cos* i.age_cat i.sex , family(nb ml) link(log) exposure(totpop) eform 

**HIV pre-pandemic
lincom 2.hivstatus, eform
**HIV post-pandemic - slightly lower (although interaction term is NS)
lincom 2.hivstatus + 1.pandemic#2.hivstatus, eform


**=======================================================
**HIV - 2 categories
**=======================================================

use Phiv2$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
**this creates 3 sin/cos pairs per year ('harmonics' referred to in Bhaskaran paper)
fourier degrees, n(3)
su sin* cos*

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died i.pandemic##i.hiv year sin* cos* i.age_cat i.sex , family(nb ml) link(log) exposure(totpop) eform 

**HIV pre-pandemic
lincom 1.hivstatus, eform
**HIV post-pandemic - slightly lower (although interaction term is NS)
lincom 1.hivstatus + 1.pandemic#1.hivstatus, eform


**======================================================================================
** Cox regression
**======================================================================================
**quick check of HRs - is conclusion similar to that from negative binomial model?	

use pip$, clear
	gen pandemic=0
		replace pandemic=1 if month>3 & year>=2020
*check current stset		
	stset	
**change scale to years	
	stset enddate, id(individual) failure(died) enter(exposure_beg) origin(dob) scale(365.25)
	sort individual _t0 _t
**this is taking way to long to run - I have given up!!	
/*
	stcox i.hivstatus##i.pandemic i.sex
	lincom 1.hivdiag,eform
	lincom 1.hivdiag + 1.hivdiag#1.pandemic, eform
*/

	gen hiv2=hivstatus
		recode hiv2 1=0 2=1 3/max=.
	stcox i.hiv2##i.pandemic i.sex
**same conclusion as frm the negative binomial - HR is slightly lower in COVID perio dbut interaction isn't significat	
	lincom 1.hiv2,eform
	lincom 1.hiv2 + 1.hiv2#1.pandemic, eform	




**===================================================================================
erase pip$.dta
erase Phiv$.dta
erase Phiv2$.dta


