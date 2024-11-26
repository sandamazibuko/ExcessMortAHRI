****
*****do file to try to replicate analysis of Bianca

cd "D:\LSHTM_current\Africa Centre\Vukuzazi\do files\Lusanda excess mortality"

clear all
set mem 1000m
set more off,permanently


********************************************************************************************************************************************

**Vukuzazi data - created by "Data creation do-file - 22 July 2023_KB.do"

use "data\vz_censoreddata.dta",clear 
**drop those who didn't attend Vuk (not sure why they are still on this file - should have fixed this in the 'creation' do file!)
	drop if visitdate==.
**then need to censor so enter at date of Vukuzazi visit (also should have done this in the 'creation' do file)
	drop if exposure_end<visitdate
**now replace start of interval for first observation- should only be one per person
	unique iintid if exposure_beg<visitdate
	replace exposure_beg=visitdate if exposure_beg<visitdate
**redo the stset (although this may not be needed since we're not using time for this analysis)
	stset enddate, fail(died) id(iintid) enter(exposure_beg)  origin(dob)
**check that this is the same as before
	gen _dif=_t-_t0
**should be the same as exposure days except on first observation (where we changed 'expsure_beg' to the date of Vukuzazi)
		count if exposure_days~=_dif
		count if exposure_days~=_dif & visitdate~=exposure_beg
		drop exposure_days
		rename _dif exposure_days

**conditions 
**TB - classify as no TB vs old/current TB
	tab tbcascade
	tab tbdiagmicro
	gen tbcat=0 if tbcascade==0
		replace tbcat=1 if tbdiagmicrorx==1
		replace tbcat=2 if tbtxever==1 & tbcat~=1
	label def tbcat 0"No TB" 1"Current TB" 2 "Past TB",modify
	label val tbcat tbcat
**are some who have no CXR evidence but no information on sputum - these could probably be no	
	tab tbcat,m

	gen tb=tbcat
		recode tb 1/2=1
	label val tb	 lblYesNo	
	label var tb "Current/past TB"
	tab tb
	
	gen tb_ext=tb
		replace tb_ext=0 if tb==. & tbtxcurrent==2 & tbtxever==2
	label val tb_ext	 lblYesNo	
	label var tb_ext "Current/past TB (extended definition)"
	tab tb_ext
	
	
**HIV	
	tab hivcascade hivelisa
	rename hivelisa hivdiag
	
**HTN
	tab htncascade htndiag,m

**DM
	tab dmcascade dmdiag,m
	
foreach var in hivdiag htndiag dmdiag {
	recode `var' 2=0
	label val `var' lblYesNo	
}	

save "data\vz_censoredatVukVisit.dta", replace


**now collapse for the Bianca analysis
use "data\vz_censoredatVukVisit.dta", clear
	unique year month iintid
**we need to count number of people in each month (denominator) & number of deaths
**denominator is population rather than time
	sort iintid year month _t0 _t
	by iintid  year month:gen pop=1 if _n==1
**should be 560,265 (as in 'unique' command above)
	tab pop
**this is so we only count people once per month - they will have 2 records in a month if their age changes 	
	
**age groups
	tab age_group died
**have 14 year old??	
	tabstat age_yrs,s(min max n) by(age_group)
	drop if age_yrs<15|age_yrs==.
	drop if sex==.
cap drop dup
bys iintid: gen dup=_n
save vuk$, replace	
strate tbcat, output(tb24,replace) nolist
strate htndiag, output(htn24,replace) nolist
strate dmdiag, output(dm24,replace) nolist
strate bmicat, output(bmi24,replace) nolist
	
**need separate datasets for each conditions
use vuk$,clear
	drop if hivdiag==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex hivdiag )
save Vhiv$, replace

use vuk$,clear
	drop if tbcat==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex tb)
save Vtb$, replace

use vuk$,clear
	drop if htndiag==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex htndiag)
save Vhtn$, replace

use vuk$,clear
	drop if dmdiag==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex dmdiag)
save Vdm$, replace

use vuk$,clear
	drop if bmicat==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex bmicat)
save Vbmi$, replace
 
use pip2$, clear
cap drop pop
unique year month iintid
**we need to count number of people in each month (denominator) & number of deaths
**denominator is population rather than time
sort iintid year month _t0 _t
by iintid  year month:gen pop=1 if _n==1
**should be 560,265 (as in 'unique' command above)
tab pop
tab age_group died
tabstat age_yrs,s(min max n) by(age_group)
drop if age_yrs<15|age_yrs==.
drop if sex==.
replace assetindexquintile=9 if assetindexquintile==.
strate assetindexquintile , output(ses24,replace) nolist
save pip2$, replace

	drop if assetindex==.
	collapse (sum) totpop=pop died=_d, by(year month age_group sex assetindex)
save Vpipses$, replace

**===================create datasets for combined analysis 
use Vuk$, clear

* Define BMI categories (3 groups: Underweight, Normal, Overweight/Obese)
gen bmi3cat = .
replace bmi3cat = 1 if bmicat == 1 // Underweight
replace bmi3cat = 2 if bmicat == 2 // Normal weight
replace bmi3cat = 3 if bmicat >= 3 & bmicat <= 4 // Overweight/Obese

* Define combined groups for BMI and Hypertension
gen bmi_htn_group = .
replace bmi_htn_group = 1 if bmi3cat == 1 & htndiag == 1 // Underweight and hypertensive
replace bmi_htn_group = 2 if bmi3cat == 1 & htndiag == 0 // Underweight, not hypertensive
replace bmi_htn_group = 3 if bmi3cat == 2 & htndiag == 1 // Normal weight, hypertensive
replace bmi_htn_group = 4 if bmi3cat == 2 & htndiag == 0 // Normal weight, not hypertensive
replace bmi_htn_group = 5 if bmi3cat == 3 & htndiag == 1 // Overweight/Obese and hypertensive
replace bmi_htn_group = 6 if bmi3cat == 3 & htndiag == 0 // Overweight/Obese, not hypertensive
* Label the combined groups
label define bmi_htn_group 1 "Underweight and hypertensive" ///
                          2 "Underweight, not hypertensive" ///
                          3 "Normal weight, hypertensive" ///
                          4 "Normal weight, not hypertensive" ///
                          5 "Overweight/Obese and hypertensive" ///
                          6 "Overweight/Obese, not hypertensive"

* Apply the label to the variable
label variable bmi_htn_group "Combined BMI and Hypertension Groups"
* Aggregate data
drop if bmi_htn_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex bmi_htn_group)
save Vbmihtn$, replace

use Vuk$, clear

* Define TB and HIV combined groups
gen tb_hiv_group = .
replace tb_hiv_group = 1 if tb_ext == 1 & hivdiag == 1 // TB and HIV-positive
replace tb_hiv_group = 2 if tb_ext == 1 & hivdiag == 0 // TB-positive, HIV-negative
replace tb_hiv_group = 3 if tb_ext == 0 & hivdiag == 1 // TB-negative, HIV-positive
replace tb_hiv_group = 4 if tb_ext == 0 & hivdiag == 0 // Neither TB nor HIV-positive

label define tb_hiv_group 1 "TB and HIV-positive" ///
                          2 "TB-positive, HIV-negative" ///
                          3 "TB-negative, HIV-positive" ///
                          4 "Neither TB nor HIV-positive"

label val tb_hiv_group tb_hiv_group
label variable tb_hiv_group "Combined TB and HIV Groups"
* Aggregate data
drop if tb_hiv_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex tb_hiv_group)
save Vtbhiv$, replace

use Vuk$, clear

* Define HIV and Hypertension combined groups
gen hiv_htn_group = .
replace hiv_htn_group = 1 if hivdiag == 1 & htndiag == 1 // HIV-positive and hypertensive
replace hiv_htn_group = 2 if hivdiag == 1 & htndiag == 0 // HIV-positive, not hypertensive
replace hiv_htn_group = 3 if hivdiag == 0 & htndiag == 1 // HIV-negative, hypertensive
replace hiv_htn_group = 4 if hivdiag == 0 & htndiag == 0 // Neither HIV nor hypertensive
label define hiv_htn_group 1 "HIV-positive and hypertensive" ///
                            2 "HIV-positive, not hypertensive" ///
                            3 "HIV-negative, hypertensive" ///
                            4 "Neither HIV nor hypertensive"
label val hiv_htn_group hiv_htn_group 
* Apply the label to the variable
label variable hiv_htn_group "Combined HIV and Hypertension Groups"
* Aggregate data
drop if hiv_htn_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex hiv_htn_group)
save Vhivhtn$, replace

use Vuk$, clear

* Define HIV and Diabetes combined groups
gen hiv_dm_group = .
replace hiv_dm_group = 1 if hivdiag == 1 & dmdiag == 1 // HIV-positive and diabetic
replace hiv_dm_group = 2 if hivdiag == 1 & dmdiag == 0 // HIV-positive, not diabetic
replace hiv_dm_group = 3 if hivdiag == 0 & dmdiag == 1 // HIV-negative, diabetic
replace hiv_dm_group = 4 if hivdiag == 0 & dmdiag == 0 // Neither HIV nor diabetic
label define hiv_dm_group 1 "HIV-positive and diabetic" ///
                           2 "HIV-positive, not diabetic" ///
                           3 "HIV-negative, diabetic" ///
                           4 "Neither HIV nor diabetic"
label val hiv_dm_group hiv_dm_group
* Apply the label to the variable
label variable hiv_dm_group "Combined HIV and Diabetes Groups"
* Aggregate data
drop if hiv_dm_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex hiv_dm_group)
save Vhivdm$, replace

use Vuk$, clear

use Vuk$, clear

* Define Hypertension and Diabetes combined groups
gen htn_dm_group = .
replace htn_dm_group = 1 if htndiag == 1 & dmdiag == 1 // Hypertensive and diabetic
replace htn_dm_group = 2 if htndiag == 1 & dmdiag == 0 // Hypertensive, not diabetic
replace htn_dm_group = 3 if htndiag == 0 & dmdiag == 1 // Non-hypertensive, diabetic
replace htn_dm_group = 4 if htndiag == 0 & dmdiag == 0 // Neither hypertensive nor diabetic

label define htn_dm_group 1 "Hypertensive and diabetic" ///
                          2 "Hypertensive, not diabetic" ///
                          3 "Non-hypertensive, diabetic" ///
                          4 "Neither hypertensive nor diabetic"
label val htn_dm_group htn_dm_group

* Apply the label to the variable
label variable htn_dm_group "Combined Hypertension and Diabetes Groups"

* Aggregate data
drop if htn_dm_group == .
collapse (sum) totpop=pop died=_d, by(year month age_group sex htn_dm_group)

save Vhtndm$, replace

use Vuk$, clear


* Define HIV and BMI combined groups
gen hiv_bmi_group = .
replace hiv_bmi_group = 1 if hivdiag == 1 & bmicat == 1 // HIV-positive and underweight
replace hiv_bmi_group = 2 if hivdiag == 1 & bmicat == 2 // HIV-positive and normal weight
replace hiv_bmi_group = 3 if hivdiag == 1 & bmicat == 3 // HIV-positive and overweight/obese
replace hiv_bmi_group = 4 if hivdiag == 0 & bmicat == 1 // HIV-negative and underweight
replace hiv_bmi_group = 5 if hivdiag == 0 & bmicat == 2 // HIV-negative and normal weight
replace hiv_bmi_group = 6 if hivdiag == 0 & bmicat == 3 // HIV-negative and overweight/obese
label define hiv_bmi_group 1 "HIV-positive and underweight" ///
                            2 "HIV-positive and normal weight" ///
                            3 "HIV-positive and overweight/obese" ///
                            4 "HIV-negative and underweight" ///
                            5 "HIV-negative and normal weight" ///
                            6 "HIV-negative and overweight/obese"
label val hiv_bmi_group hiv_bmi_group 
* Apply the label to the variable
label variable hiv_bmi_group "Combined HIV and BMI Groups"
* Aggregate data
drop if hiv_bmi_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex hiv_bmi_group)
save Vhivbmi$, replace

***BMI + Diabetes
use Vuk$, clear

* Redefine BMI categories if not already done
gen bmi3cat = .
replace bmi3cat = 1 if bmicat == 1 // Underweight
replace bmi3cat = 2 if bmicat == 2 // Normal weight
replace bmi3cat = 3 if bmicat >= 3 & bmicat <= 4 // Overweight/Obese

* Define BMI and Diabetes combined groups
gen bmi_dm_group = .
replace bmi_dm_group = 1 if bmi3cat == 1 & dmdiag == 1 // Underweight and diabetic
replace bmi_dm_group = 2 if bmi3cat == 1 & dmdiag == 0 // Underweight, not diabetic
replace bmi_dm_group = 3 if bmi3cat == 2 & dmdiag == 1 // Normal weight and diabetic
replace bmi_dm_group = 4 if bmi3cat == 2 & dmdiag == 0 // Normal weight, not diabetic
replace bmi_dm_group = 5 if bmi3cat == 3 & dmdiag == 1 // Overweight/Obese and diabetic
replace bmi_dm_group = 6 if bmi3cat == 3 & dmdiag == 0 // Overweight/Obese, not diabetic
* Label the combined groups
label define bmi_dm_group 1 "Underweight and diabetic" ///
                           2 "Underweight, not diabetic" ///
                           3 "Normal weight and diabetic" ///
                           4 "Normal weight, not diabetic" ///
                           5 "Overweight/Obese and diabetic" ///
                           6 "Overweight/Obese, not diabetic"
label variable bmi_dm_group "Combined BMI and Diabetes Groups"
label val bmi_dm_group  bmi_dm_group 
* Aggregate data
drop if bmi_dm_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex bmi_dm_group)
save Vbmidm$, replace

use Vuk$, clear
// Define BMI Categories
gen bmi_group = .
replace bmi_group = 1 if bmicat == 1  // Underweight
replace bmi_group = 2 if bmicat == 2  // Normal weight
replace bmi_group = 3 if bmicat >= 3 & bmicat <= 4  // Overweight/Obese

// Define TB Status
gen tb_status = .
replace tb_status = 1 if tb_ext == 1  // TB diagnosed in the past or current 
replace tb_status = 0 if tb_ext == 0  // No TB ever 

// Combine TB and BMI Categories
gen tb_bmi_group = .
replace tb_bmi_group = 1 if tb_status == 1 & bmi_group == 1  // TB + Underweight
replace tb_bmi_group = 2 if tb_status == 1 & bmi_group == 2  // TB + Normal weight
replace tb_bmi_group = 3 if tb_status == 1 & bmi_group == 3  // TB + Overweight/Obese
replace tb_bmi_group = 4 if tb_status == 0 & bmi_group == 1  // No TB + Underweight
replace tb_bmi_group = 5 if tb_status == 0 & bmi_group == 2  // No TB + Normal weight
replace tb_bmi_group = 6 if tb_status == 0 & bmi_group == 3  // No TB + Overweight/Obese
label define tb_bmi_group 1 "TB + Underweight" ///
                           2 "TB + Normal weight" ///
                           3 "TB + Overweight/Obese" ///
                           4 "No TB + Underweight" ///
                           5 "No TB + Normal weight" ///
                           6 "No TB + Overweight/Obese"
label val tb_bmi_group tb_bmi_group
* Apply the label to the variable
label variable tb_bmi_group "Combined TB and BMI Groups"
drop if tb_bmi_group==.
collapse (sum) totpop=pop died=_d, by(year month age_group sex tb_bmi_group)

save Vtbbmi$, replace

use Vuk$, clear

* Define TB and Diabetes combined groups
gen tb_status = .
replace tb_status = 1 if tb_ext == 1  // TB diagnosed in the past or current 
replace tb_status = 0 if tb_ext == 0  // No TB ever 

gen tb_dm_group = .
replace tb_dm_group = 1 if tb_status == 1 & dmdiag == 1 // TB-positive and diabetic
replace tb_dm_group = 2 if tb_status == 1 & dmdiag == 0 // TB-positive, not diabetic
replace tb_dm_group = 3 if tb_status == 0 & dmdiag == 1 // Non-TB, diabetic
replace tb_dm_group = 4 if tb_status == 0 & dmdiag == 0 // Neither TB nor diabetic

label define tb_dm_group 1 "TB-positive and diabetic" ///
                         2 "TB-positive, not diabetic" ///
                         3 "Non-TB, diabetic" ///
                         4 "Neither TB nor diabetic"
label val tb_dm_group tb_dm_group

* Apply the label to the variable
label variable tb_dm_group "Combined TB and Diabetes Groups"

* Aggregate data
drop if tb_dm_group == . 
collapse (sum) totpop=pop died=_d, by(year month age_group sex tb_dm_group)

save Vtbdm$, replace

use Vuk$, clear
* Define TB and Diabetes combined groups
gen tb_status = .
replace tb_status = 1 if tb_ext == 1  // TB diagnosed in the past or current 
replace tb_status = 0 if tb_ext == 0  // No TB ever 


* Define TB and Hypertension combined groups
gen tb_htn_group = .
replace tb_htn_group = 1 if tb_status == 1 & htndiag == 1 // TB-positive and hypertensive
replace tb_htn_group = 2 if tb_status == 1 & htndiag == 0 // TB-positive, not hypertensive
replace tb_htn_group = 3 if tb_status == 0 & htndiag == 1 // Non-TB, hypertensive
replace tb_htn_group = 4 if tb_status == 0 & htndiag == 0 // Neither TB nor hypertensive

label define tb_htn_group 1 "TB-positive and hypertensive" ///
                          2 "TB-positive, not hypertensive" ///
                          3 "Non-TB, hypertensive" ///
                          4 "Neither TB nor hypertensive"
label val tb_htn_group tb_htn_group

* Apply the label to the variable
label variable tb_htn_group "Combined TB and Hypertension Groups"

* Aggregate data
drop if tb_htn_group == .
collapse (sum) totpop=pop died=_d, by(year month age_group sex tb_htn_group)

save Vtbbmihtn$, replace

**=====================================================================================
**analysis


**=======================================================
**HIV
**=======================================================

use Vhiv$, clear

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

glm died year sin* cos* ib65.age i.sex i.pandemic, family(nb ml) link(log) exposure(totpop) eform 
predict fv1
**observed vs fitted
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3"Jul2018" 9 "Jan2019" 15"Jul2019" 21"Jan2020" 27"July2020" 33"Jan2021" 39"Jul2021", angle(45) labsize(vsmall)) 


glm died i.pandemic##i.hivdiag year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**HIV pre-pandemic
lincom 1.hivdiag, eform
**HIV post-pandemic - slightly lower (although interaction term is NS)
lincom 1.hivdiag + 1.pandemic#1.hivdiag, eform


**=======================================================
** HTN
**=======================================================

use Vhtn$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
su sin* cos*

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died i.pandemic##i.htndiag year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**Hypertension pre-pandemic
lincom 1.htndiag, eform
**Hypertension post-pandemic - slightly higher although interaction term is NS
lincom 1.htndiag + 1.pandemic#1.htndiag, eform

**=======================================================
** DM
**=======================================================

use Vdm$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
su sin* cos*

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died i.pandemic##i.dmdiag year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**DM pre-pandemic
lincom 1.dmdiag, eform
**DM post-pandemic - slightly lower although interaction term is NS
lincom 1.dmdiag + 1.pandemic#1.dmdiag, eform


**=======================================================
** TB
**=======================================================

use Vtb$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
su sin* cos*

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died i.pandemic##i.tb year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**TB pre-pandemic
lincom 1.tb, eform
**TB post-pandemic - lower & interaction is significant
lincom 1.tb + 1.pandemic#1.tb, eform


**=======================================================
** BMI
**=======================================================

use Vbmi$, clear

**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
su sin* cos*

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

**note that the option 'exposure' will log transform the offset
glm died i.pandemic##ib2.bmicat year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**UW pre-pandemic
lincom 1.bmicat, eform
**UW post-pandemic - lower & interaction is significant
lincom 1.bmicat + 1.pandemic#1.bmicat, eform

**obese pre-pandemic
lincom 4.bmicat, eform
**obese post-pandemic - lower & interaction is significant
lincom 4.bmicat + 1.pandemic#4.bmicat, eform

**===========================================================
** SES
**===========================================================
use Vpipses$, clear
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

glm died year sin* cos* ib65.age i.sex i.pandemic, family(nb ml) link(log) exposure(totpop) eform 
predict fv1
**observed vs fitted
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3"Jul2018" 9 "Jan2019" 15"Jul2019" 21"Jan2020" 27"July2020" 33"Jan2021" 39"Jul2021", angle(45) labsize(vsmall)) 


glm died i.pandemic##i.assetindex year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 

**SES pre-pandemic
lincom 2.assetindex, eform
lincom 3.assetindex, eform
lincom 4.assetindex, eform
lincom 5.assetindex, eform
**SES post-pandemic 
lincom 2.assetindex + 1.pandemic#2.assetindex, eform
lincom 3.assetindex + 1.pandemic#3.assetindex, eform
lincom 4.assetindex + 1.pandemic#4.assetindex, eform
lincom 5.assetindex + 1.pandemic#5.assetindex, eform


**===============================================================================================
** DM and BMI 
**===============================================================================================

use Vbmidm$, clear 
**to get Fourier terms - 
gen degrees=(month/12)*360
su degrees
**this creates 3 sin/cos pairs per year ('harmonics' referred to in Bhaskaran paper)
fourier degrees, n(3)
su sin* cos*
**check 
egen time=group(year month)
drop if totpop==0
twoway (line sin_1 time) (line  cos_1 time, lcolor(red))
**looks very jagged - probably b/c this is per month rather than week
twoway (line sin_1 time,lcolor(blue)) (line  sin_2 time, lcolor(red)) (line  sin_3 time, lcolor(green))

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

glm died ib4.bmi_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform
predict fv1
**observed vs fitted
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3"Jul2018" 9 "Jan2019" 15"Jul2019" 21"Jan2020" 27"July2020" 33"Jan2021" 39"Jul2021", angle(45) labsize(vsmall)) 

label define bmi_dm_group 1 "Underweight and diabetic" 2 "Underweight, not diabetic" ///
                            3 "Normal weight and diabetic" 4 "Normal weight, not diabetic" ///
                            5 "Overweight/Obese and diabetic" 6 "Overweight/Obese, not diabetic"

label values bmi_dm_group bmi_dm_group


**Pre-pandemic vs during 
lincom 1.bmi_dm_group, eform // Pre-pandemic
lincom 1.bmi_dm_group + 1.pandemic#1.bmi_dm_group, eform // during pandemic

lincom 2.bmi_dm_group, eform // Pre-pandemic
lincom 2.bmi_dm_group + 1.pandemic#2.bmi_dm_group, eform // during -pandemic

lincom 3.bmi_dm_group, eform // Pre-pandemic
lincom 3.bmi_dm_group + 1.pandemic#3.bmi_dm_group, eform // during pandemic

lincom 4.bmi_dm_group, eform // Pre-pandemic
lincom 4.bmi_dm_group + 1.pandemic#4.bmi_dm_group, eform // during pandemic

lincom 5.bmi_dm_group, eform // Pre-pandemic
lincom 5.bmi_dm_group + 1.pandemic#5.bmi_dm_group, eform // during pandemic

lincom 6.bmi_dm_group, eform // Pre-pandemic
lincom 6.bmi_dm_group + 1.pandemic#6.bmi_dm_group, eform // during pandemic

cap postclose p2
postfile p2 str25 group str15 period float irr float lb float ub using obesity_dm_table, replace

foreach g in 1 2 3 4 5 6 { 
    // Pre-Pandemic IRR
    lincom `g'.bmi_dm_group, eform
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p2 ("Group `g'") ("Pre-Pandemic") (`irr') (`lb') (`ub')
    
    // Post-Pandemic IRR
    lincom `g'.bmi_dm_group + 1.pandemic#`g'.bmi_dm_group, eform
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p2 ("Group `g'") ("during pandemic") (`irr') (`lb') (`ub')
}

postclose p2
use obesity_dm_table, clear
list



**=====================================================================================
** HTN and BMI 
**=====================================================================================
use Vbmihtn$, clear

gen degrees=(month/12)*360
su degrees
**this creates 3 sin/cos pairs per year ('harmonics' referred to in Bhaskaran paper)
fourier degrees, n(3)
su sin* cos*
**check 
egen time=group(year month)
drop if totpop==0
twoway (line sin_1 time) (line  cos_1 time, lcolor(red))
**looks very jagged - probably b/c this is per month rather than week
twoway (line sin_1 time,lcolor(blue)) (line  sin_2 time, lcolor(red)) (line  sin_3 time, lcolor(green))

gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3

// GLM model with interaction
glm died ib4.bmi_htn_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs Post-Pandemic IRRs
foreach g in 1 2 3 4 5 6 { 
    lincom `g'.bmi_htn_group, eform
    lincom `g'.bmi_htn_group + 1.pandemic#`g'.bmi_htn_group, eform
}

**=======================================================================================
** HIV and TB
**=======================================================================================
use Vtbhiv$, clear

// Fourier terms
gen degrees = (month / 12) * 360
fourier degrees, n(3)
**check 
egen time=group(year month)
drop if totpop==0
twoway (line sin_1 time) (line  cos_1 time, lcolor(red))

// Pandemic indicator
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

// GLM model with interaction
glm died ib4.tb_hiv_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs during Pandemic IRRs
foreach g in 1 2 3 4 { 
    lincom `g'.tb_hiv_group, eform
    lincom `g'.tb_hiv_group + 1.pandemic#`g'.tb_hiv_group, eform
}

use Vtbhiv$, clear

gen degrees = (month / 12) * 360
fourier degrees, n(3)

egen time = group(year month)
drop if totpop == 0

gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

glm died ib4.tb_hiv_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/4 {
    lincom `i'.tb_hiv_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_hiv_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.tb_hiv_group + 1.pandemic#`i'.tb_hiv_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_hiv_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1


**=====================================================================================
** HTN and HIV-
**=====================================================================================
use Vhivhtn$, clear

gen degrees = (month / 12) * 360
fourier degrees, n(3)

egen time = group(year month)
drop if totpop == 0

gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

// GLM model with interaction
glm died ib4.hiv_htn_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs Pandemic IRRs
foreach g in 1 2 3 4 { 
    lincom `g'.hiv_htn_group, eform
    lincom `g'.hiv_htn_group + 1.pandemic#`g'.hiv_htn_group, eform
}

use Vhivhtn$, clear
gen degrees = (month / 12) * 360
fourier degrees, n(3)
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3
glm died ib4.hiv_htn_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/4 {
    lincom `i'.hiv_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_htn_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.hiv_htn_group + 1.pandemic#`i'.hiv_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_htn_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1

**===================================================================================
** HIV and DM 
**===================================================================================

use Vhivdm$, clear
gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3
// GLM model with interaction
glm died ib4.hiv_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs Pandemic IRRs
foreach g in 1 2 3 4 { 
    lincom `g'.hiv_dm_group, eform
    lincom `g'.hiv_dm_group + 1.pandemic#`g'.hiv_dm_group, eform
}

glm died ib4.hiv_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/4 {
    lincom `i'.hiv_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_dm_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.hiv_dm_group + 1.pandemic#`i'.hiv_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_dm_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1

**=====================================================================================
** HTN and DM 
**=====================================================================================
use Vhtndm$, clear
gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3
// GLM model with interaction
glm died ib4.htn_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs Pandemic IRRs
foreach g in 1 2 3 4 { 
    lincom `g'.htn_dm_group, eform
    lincom `g'.htn_dm_group + 1.pandemic#`g'.htn_dm_group, eform
}

glm died ib4.htn_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/4 {
    lincom `i'.htn_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("htn_dm_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.htn_dm_group+ 1.pandemic#`i'.htn_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("htn_dm_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1



**=====================================================================================
** HIV and BMI
**=====================================================================================
use Vhivbmi$, clear

gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

// GLM model with interaction
glm died ib5.hiv_bmi_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

// Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

// Pre-Pandemic vs Pandemic IRRs
foreach g in 1 2 3 4 5 6 { 
    lincom `g'.hiv_bmi_group, eform
    lincom `g'.hiv_bmi_group + 1.pandemic#`g'.hiv_bmi_group, eform
}

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/6 {
    lincom `i'.hiv_bmi_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_bmi_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.hiv_bmi_group + 1.pandemic#`i'.hiv_bmi_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("hiv_bmi_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1


**======================================================================================
** TB and BMI
**======================================================================================
use Vtbbmi$, clear

gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

* GLM model with interaction
glm died ib5.tb_bmi_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

* Predicted vs observed
predict fv1
twoway (line died time) (line fv1 time, lcolor(red)), xlabel(3 "Jul2018" 9 "Jan2019" 15 "Jul2019" 21 "Jan2020" 27 "Jul2020" 33 "Jan2021" 39 "Jul2021", angle(45) labsize(vsmall))

* Pre-Pandemic vs Pandemic IRRs
foreach g in 1 2 3 4 5 6 { 
    lincom `g'.tb_bmi_group, eform
    lincom `g'.tb_bmi_group + 1.pandemic#`g'.tb_bmi_group, eform
}

postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

forval i = 1/6 {
    lincom `i'.tb_bmi_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_bmi_group`i'") (0) (`irr') (`lb') (`ub')
    
    lincom `i'.tb_bmi_group + 1.pandemic#`i'.tb_bmi_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_bmi_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1


**======================================================================================
** TB and DM 
**======================================================================================
use Vtbdm$, clear
gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

* GLM model with interaction for TB and DM groups
glm died ib4.tb_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

* Open a postfile to store results for TB and DM
postfile p1 str32 group byte pandemic double irr double lb double ub using tb_dm_results.dta, replace

* Loop through the 4 levels of `tb_dm_group`
forval i = 1/4 {
    lincom `i'.tb_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_dm_group`i'") (0) (`irr') (`lb') (`ub')
    lincom `i'.tb_dm_group + 1.pandemic#`i'.tb_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("tb_dm_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p1

**======================================================================================
** TB and hypertension
**======================================================================================
use Vtbbmihtn$, clear
gen degrees = (month / 12) * 360
fourier degrees, n(3)
egen time = group(year month)
drop if totpop == 0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

* GLM model with interaction for TB and HTN groups
glm died ib4.tb_htn_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

* Open a postfile to store results for TB and HTN
postfile p2 str32 group byte pandemic double irr double lb double ub using tb_htn_results.dta, replace

* Loop through the 4 levels of `tb_htn_group`
forval i = 1/4 {
    lincom `i'.tb_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p2 ("tb_htn_group`i'") (0) (`irr') (`lb') (`ub')
    lincom `i'.tb_htn_group + 1.pandemic#`i'.tb_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p2 ("tb_htn_group`i'") (1) (`irr') (`lb') (`ub')
}

postclose p2





**======================================================================================
** Cox regression
**======================================================================================
**quick check of HRs - is conclusion similar to that from negative binomial model?	

use "data\vz_censoredatVukVisit.dta", clear
	gen pandemic=0
		replace pandemic=1 if month>3 & year>=2020
	stset enddate, id(iintid) failure(died) enter(exposure_beg) origin(dob) scale(365.25)
	strate pandemic hivdiag,per(100)	
	
**will adjust for SES too	
	stcox i.hivdiag##i.pandemic i.sex i.sescat
	lincom 1.hivdiag,eform
	lincom 1.hivdiag + 1.hivdiag#1.pandemic, eform

	stcox i.dmdiag##i.pandemic i.sex i.sescat
	lincom 1.dmdiag,eform
	lincom 1.dmdiag + 1.pandemic#1.dmdiag, eform

	stcox i.htndiag##i.pandemic i.sex i.sescat
	lincom 1.htndiag,eform
	lincom 1.htndiag + 1.pandemic#1.htndiag, eform

**conlusions the same but difference is more dramatic here 
	stcox i.tb##i.pandemic i.sex i.sescat
	lincom 1.tb,eform
	lincom 1.tb + 1.pandemic#1.tb, eform



**======================================================================================
**create a table & the figure like Bianca's


cap postclose p1
qui {
postfile p1 str10 morbid pandemic irr lb ub using res1, replace
foreach var in hiv htn dm tb  { 
use V`var'$, clear	
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3
glm died i.pandemic##i.`var' year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 	
	lincom 1.`var'
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))
post p1 ("`var'") (0) (`irr') (`lb') (`ub')
	
	lincom 1.`var' + 1.pandemic#1.`var'
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))	
post p1 ("`var'") (1) (`irr') (`lb') (`ub')
}
use Vbmi$, clear	
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3
glm died i.pandemic##ib2.bmicat year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 	
forval i=1/4 {
	lincom `i'.bmicat
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))
post p1 ("bmicat`i'") (0) (`irr') (`lb') (`ub')
	lincom `i'.bmicat + 1.pandemic#`i'.bmicat
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))	
post p1 ("bmicat`i'") (1) (`irr') (`lb') (`ub')
}	
use Vpipses$, clear	
gen degrees=(month/12)*360
su degrees
fourier degrees, n(3)
gen pandemic=0
	replace pandemic=1 if year>=2020 & month>3
glm died i.pandemic##ib1.assetindex year sin* cos* ib65.age i.sex , family(nb ml) link(log) exposure(totpop) eform 	
forval i=1/5 {
	lincom `i'.assetindex
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))
post p1 ("assetindex`i'") (0) (`irr') (`lb') (`ub')
	lincom `i'.assetindex + 1.pandemic#`i'.assetindex
	local irr:  di %-5.2f exp(r(estimate))
	local lb:  di %-5.2f exp(r(lb))
	local ub:  di %-5.2f exp(r(ub))	
post p1 ("assetindex`i'") (1) (`irr') (`lb') (`ub')
}
}	
postclose p1	

* Load the dataset and prepare the degrees variable
use Vbmidm$, clear	
gen degrees = (month / 12) * 360

* Summarize degrees and fit Fourier terms
su degrees
fourier degrees, n(3)
drop if totpop==0

* Create a pandemic variable: 1 for years 2020 and beyond, starting from April
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

* Fit the generalized linear model (GLM) with exposure
glm died ib4.bmi_dm_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

* Open a postfile to store results
postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

* Loop through the 6 levels of `bmi_dm_group`
forval i = 1/6 {
    * Compute the `lincom` for `bmi_dm_group` without pandemic interaction
    lincom `i'.bmi_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    
    * Post results for `bmi_dm_group` without interaction
    post p1 ("bmi_dm_group`i'") (0) (`irr') (`lb') (`ub')

    * Compute the `lincom` for `bmi_dm_group` with the pandemic interaction
    lincom `i'.bmi_dm_group + 1.pandemic#`i'.bmi_dm_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    
    * Post results for `bmi_dm_group` with interaction
    post p1 ("bmi_dm_group`i'") (1) (`irr') (`lb') (`ub')
}

* Close the postfile
postclose p1

use Vbmihtn$, clear	
gen degrees = (month / 12) * 360
su degrees
fourier degrees, n(3)
drop if totpop==0
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3
glm died ib4.bmi_htn_group##i.pandemic year sin* cos* ib65.age i.sex, family(nb ml) link(log) exposure(totpop) eform

* Open a postfile to store results
postfile p1 str32 group byte pandemic double irr double lb double ub using results.dta, replace

* Loop through the 6 levels of `bmi_htn_group`
forval i = 1/6 {
    lincom `i'.bmi_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    post p1 ("bmi_htn_group`i'") (0) (`irr') (`lb') (`ub')
    lincom `i'.bmi_htn_group + 1.pandemic#`i'.bmi_htn_group
    local irr: di %-5.2f exp(r(estimate))
    local lb: di %-5.2f exp(r(lb))
    local ub: di %-5.2f exp(r(ub))
    
    * Post results for `bmi_dm_group` with interaction
    post p1 ("bmi_htn_group`i'") (1) (`irr') (`lb') (`ub')
}

* Close the postfile
postclose p1


use res1, clear		
		gen ct=_n
		replace ct=ct+1 if ct>2
		replace ct=ct+1 if ct>5
		replace ct=ct+1 if ct>8
		replace ct=ct+2 if ct>11
		
		gen labpos=0.1
		replace morbid="HIV" if morbid=="hiv"
		replace morbid= "Hypertension" if morbid=="htn"
		replace morbid= "Diabetes" if morbid=="dm"
		replace morbid= "TB (current/past)" if morbid=="tb"
		replace morbid= "Underweight" if morbid=="bmicat1"
		replace morbid= "Normal weight" if morbid=="bmicat2"
		replace morbid= "Overweight" if morbid=="bmicat3"
		replace morbid= "Obese" if morbid=="bmicat4"
		replace morbid= "1 (most deprived)" if morbid="assetindex1"
		replace morbid= "2" if morbid="assetindex2"
		replace morbid= "3" if morbid="assetindex3"
		replace morbid= "4" if morbid="assetindex4"
        replace morbid= "5 (least deprived)" if morbid="assetindex5"
save res1$, replace	
		
		
#delimit ;
		graph twoway (rcap lb ub ct if pandemic==0  ,sort lc(navy) horizontal  )
	(scatter ct irr if pandemic==0,sort ms(T) msize(medium) mc(navy) lp(solid) lw(medium) lc(cranberry))
	(rcap lb ub ct if pandemic==1 ,sort lc(cranberry) horizontal  )
		(scatter ct irr if pandemic==1 ,sort ms(O) msize(medium) mc(cranberry) lp(solid) lw(medium) lc(cranberry))	
		(scatter ct labpos if pandemic==0 ,sort mlabel(morbid) ms(none) mlabcolor(black) mlabsize(medium)) 		,
	ysize(5) xsize(3)
	title(" " , span size(medium))
	xscale(titlegap(2)) 
	ytitle(" ")
	yscale(reverse off r(0 22) )
	xscale(log)
	xline(1, lc(black) lstyle(solid)) 
	xtitle("Rate ratio & 95% CI")
	text(12.8 0.1 "{bf}BMI category", size(medium) placement(e))	
	
	xlab(0 "0" 0.50 "0.50"  1 "1.0"  2.5 "2.5" 5 "5.0"  , labsize(medium) gmax angle(horizontal))
	graphregion(fcolor(white) ifcolor(white))  
legend(order(2 "RR pre-pandemic" 4 "RR during COVID" ) pos(6) rows(1))	;
	#delimit cr
	
graph export "graphs\RRs_prepost_BMI_ses.tif", as(tif) replace


**without BMI
use res1$, clear
	drop if ct>12

#delimit ;
		graph twoway (rcap lb ub ct if pandemic==0   ,sort lc(navy) horizontal  )
	(scatter ct irr if pandemic==0 ,sort ms(T) msize(medium) mc(navy) lp(solid) lw(medium) lc(cranberry))
	(rcap lb ub ct if pandemic==1 ,sort lc(cranberry) horizontal  )
		(scatter ct irr if pandemic==1  ,sort ms(O) msize(medium) mc(cranberry) lp(solid) lw(medium) lc(cranberry))	
		(scatter ct labpos if pandemic==0 ,sort mlabel(morbid) ms(none) mlabcolor(black) mlabsize(medium)) 		,
	ysize(5) xsize(3)
	title(" " , span size(medium))
	xscale(titlegap(2)) 
	ytitle(" ")
	yscale(reverse off r(0 12) )
	xscale(log)
	xline(1, lc(black) lstyle(solid)) 
	xtitle("Rate ratio & 95% CI")
	xlab(0 "0" 0.50 "0.50"  1 "1.0"  2.5 "2.5" 5 "5.0"  , labsize(medium) gmax angle(horizontal))
	graphregion(fcolor(white) ifcolor(white))  
legend(order(2 "RR pre-pandemic" 4 "RR during COVID" ) pos(6) rows(1))	;
	#delimit cr
	
graph export "graphs\RRs_prepost.tif", as(tif) replace


**========================================================
**Table

use "data\vz_censoredatVukVisit.dta", clear
	gen pandemic=0
		replace pandemic=1 if month>3 & year>=2020
	stset enddate, id(iintid) failure(died) enter(exposure_beg) origin(dob) scale(365.25)
	
qui {
tempname table
file open `table' using "output/table_HR.txt", write replace
file write `table'  _tab "pre-pandemic"  _tab  _tab "COVID"  
file write `table'  _n "Factor" _tab "deaths/person years"  _tab "HR (95%CI)"   _tab "deaths/person years"  _tab "HR (95%CI)"  

foreach var in hivdiag htndiag dmdiag tb  {
	local varlab: variable label `var'
	file write `table' _n "`varlab'"  	
	stcox i.`var'##i.pandemic i.sex
	estimates store h
levelsof `var', local(elist)	
foreach e in `elist' {
		local xlab: label(`var') `e'
		count if _d==1 & `var'==`e' & pandemic==0 
		local d0_`e'=r(N)
		count if _d==1 & `var'==`e' & pandemic==1 
		local d1_`e'=r(N)
		stsum if `var'==`e' & pandemic==0
		local y0_`e': di %-4.0f r(risk)	
		stsum if `var'==`e' & pandemic==1
		local y1_`e': di %-4.0f r(risk)		
	estimates restore h
	lincom `e'.`var'
	local rrB:  di %-5.2f exp(r(estimate))
	local lbB:  di %-5.2f exp(r(lb))
	local ubB:  di %-5.2f exp(r(ub))		
	
	lincom `e'.`var' + `e'.`var'#1.pandemic
	local rrA:  di %-5.2f exp(r(estimate))
	local lbA:  di %-5.2f exp(r(lb))
	local ubA:  di %-5.2f exp(r(ub))		
	
file write `table'  _n "`xlab'"  _tab "`d0_`e''/`y0_`e''" _tab "`rrB' (`lbB'-`ubB')"  _tab "`d1_`e''/`y1_`e''"   _tab  "`rrA' (`lbA'-`ubA')"
}
}
**BMI
	file write `table' _n "BMI category"  	
	stcox ib2.bmicat##i.pandemic i.sex
	estimates store h
levelsof bmicat, local(elist)	
foreach e in `elist' {
		local xlab: label(bmicat) `e'
		count if _d==1 & bmicat==`e' & pandemic==0 
		local d0_`e'=r(N)
		count if _d==1 & bmicat==`e' & pandemic==1 
		local d1_`e'=r(N)
		stsum if bmicat==`e' & pandemic==0
		local y0_`e': di %-4.0f r(risk)	
		stsum if bmicat==`e' & pandemic==1
		local y1_`e': di %-4.0f r(risk)		
	estimates restore h
	lincom `e'.bmicat
	local rrB:  di %-5.2f exp(r(estimate))
	local lbB:  di %-5.2f exp(r(lb))
	local ubB:  di %-5.2f exp(r(ub))		
	
	lincom `e'.bmicat + `e'.bmicat#1.pandemic		
	local rrA:  di %-5.2f exp(r(estimate))
	local lbA:  di %-5.2f exp(r(lb))
	local ubA:  di %-5.2f exp(r(ub))		
	
file write `table'  _n "`xlab'"  _tab "`d0_`e'' / `y0_`e''" _tab "`rrB' (`lbB'-`ubB')"  _tab "`d1_`e'' / `y1_`e''"   _tab  "`rrA' (`lbA'-`ubA')"
}
}
file close `table'


**=====================COMBINED ANALYSIS ==========================================
* Load the first dataset
use Vhiv$, clear
gen source = "HIV"  // Add a source variable for tracking

* Append the other datasets
append using Vhtn$ 
replace source = "HTN" if source == ""

append using Vdm$
replace source = "DM" if source == ""

append using Vtb$
replace source = "TB" if source == ""

append using Vbmi$
replace source = "BMI" if source == ""

append using Vpipses$
replace source = "SES" if source == ""

* Check the combined dataset
list source if source != ""

* Generate Fourier terms for seasonality
gen degrees = (month / 12) * 360
fourier degrees, n(3)

* Create a pandemic indicator
gen pandemic = 0
replace pandemic = 1 if year >= 2020 & month > 3

* Run the combined model
glm died i.hivdiag i.dmdiag i.htndiag i.tb ib2.bmicat ///
    i.assetindex year sin* cos* ib65.age i.sex ///
    i.pandemic##(i.hivdiag i.dmdiag i.htndiag i.tb ib2.bmicat i.assetindex), ///
    family(nb ml) link(log) exposure(totpop) eform

* Review results
estimates table

**interaction term maybe 
i.pandemic##(i.hivdiag i.dmdiag)



**===================================================================================
erase vuk$.dta
erase Vdm$.dta
erase Vhiv$.dta
erase Vhtn$.dta
erase Vbmi$.dta
erase Vtb$.dta
erase res1.dta
erase res1$.dta


