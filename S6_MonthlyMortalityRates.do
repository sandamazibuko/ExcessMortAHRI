
if "${sitename}" == "BD011" {
	local site = "Matlab (BD011)"
	}
else if "${sitename}" == "BD013" {
	local site = "Chakaria (BD013)"
	}
else if "${sitename}" == "BD014" {
	local site = "Dhaka (BD014)"
	}
else if "${sitename}" == "BF021" {
	local site = "Nanoro (BF021)"
	}
else if "${sitename}" == "ET041" {
	local site = "Kersa (ET041)"
	}
else if "${sitename}" == "GH011" {
	local site = "Navrongo (GH011)"
	}
else if "${sitename}" == "KE021" {
	local site = "Siaya-Karemo (KE021)"
	}
else if "${sitename}" == "KE022" {
	local site = "Manyatta (KE022)"
	}
else if "${sitename}" == "MW011" {
	local site = "Karonga (MW011)"
	}
else if "${sitename}" == "MZ011" {
	local site = "Manhica (MZ011)"
	}
else if "${sitename}" == "TZ021" {
	local site = "Magu (TZ021)"
	}
else if "${sitename}" == "ZA011" {
	local site = "Agincourt (ZA011)"
	}
else if "${sitename}" == "ZA021" {
	local site = "Dimamo (ZA021)"
	}
else if "${sitename}" == "ZA031" {
	local site = "AHRI (ZA031)"
	}
else if "${sitename}" == "ZA081" {
	local site = "Soweto (ZA081)"
	}
	
//stsplit the data on first day of each month (e.g "01/01/2015", "01/02/2015")
use "data\RawCensoredEpisodes_calendaer_st_ready_KB", clear
local splits = ""
foreach y of numlist 2015(1)2022 {
	foreach m of numlist 1(1)12 {
		local d = "`y'/`m'/01"
		local n = date("`d'", "YMD")
		local splits = "`splits'" + " `n'"
		}
	//di date("`d'", "MDY")
	
}
di "`splits'"

/*
di date("2015/01/01", "YMD")
di date("2015/02/01", "YMD")
*/

stsplit exposure_beg, at("`splits'")
format exposure_beg %td
gen exposure_days = _t - _t0
gen month = month(exposure_beg)
cap drop year
gen year = year(exposure_beg)
gen exposure_end = _t - 1 
format exposure_end %td
sort individualid _t0
bys individualid: replace exposure_beg = _t0 if _n == 1
bys individualid: replace exposure_end = _t if _n == _N
save "data\RawCensoredEpisodes_month_split", replace
export delimited using "data\RawCensoredEpisodes_month_split.csv", replace

//split by year, month and age group
use "data\RawCensoredEpisodes_month_split", clear
drop _st _d _t _t0 exposure_days 
stset enddate, id(individualid) fail(died) enter(exposure_beg) origin(dob) 
save "data\RawCensoredEpisodes_month_split_st_age_ready", replace

stsplit age_days, at(0(365.25)36525)
//create standard WHO  age groups
gen age_yrs = age_days/365.25
keep if age_yrs >=15
recode age_yrs (15/44=15) (45/64=45) ///
	(65/max=65), gen(age_group)

//create 5 year age groups
gen age_group5= int(age_yrs/5)*5 //lower limit of 5 year age groups
//set upper age bound at 85
replace age_group5 = 85  if age_group5 > 85 & age_group5 != .

//create 10 year age groups
gen age_group10= int(age_yrs/10)*10 //lower limit of 10 year age groups
//set upper age bound at 80
replace age_group10 = 80  if age_group10 > 80 & age_group10 != .


//create life table age groups by spliting 0-4 age group into age 0 and age 1-4
gen age_lt = age_group5
replace age_lt = 1 if age_yrs >= 1 & age_yrs < 5

replace exposure_beg = _t0 + dob
replace exposure_end = _t + dob - 1 
sort individualid _t0
bys individualid: replace exposure_end = _t + dob if _n == _N
bys individualid: replace exposure_beg = startdate if _n == 1
gen exposure_days = enddate - exposure_beg
save "data\RawCensoredEpisodes_month_age_split_KB", replace
export delimited using "${data}/${sitename}_RawCensoredEpisodes_month_age_split.csv", replace

//mortality rates by month, year and age group
use "${data}/${sitename}_RawCensoredEpisodes_month_age_split", clear
strate year month age_group, output("${data}/${sitename}_py_mx_month_age",replace) nolist
use "${data}/${sitename}_py_mx_month_age", clear
format _Y %9.0g

replace _Rate = _Rate
replace _Lower = _Lower
replace _Upper = _Upper
rename _D Deaths
rename _Y PersonDays  //exposure is in days
rename _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
* correct for DAYS time scale
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
egen TotPY = sum(PersonYears) //convert exposure from days to years
gen mx_1000 = (Deaths/PersonYears)*1000
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
gen centreid = "${sitename}"
save "${data}/${sitename}_py_mx_month_age",replace

tab age_group if Lower95Mx==. & year <2022

//plot mortality rates by month, year and sex
use "${data}/${sitename}_py_mx_month_age", clear
merge m:1 year month using "${data}/year_month_month_no"

twoway (line mx_1000 month_no if month_no <= 85 & age_group==0,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
	,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (2) 14,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month for age 0-4: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month_Age0,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month_Age0.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age0.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age0.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age0.tif", replace

	
twoway (line mx_1000 month_no if month_no <= 85 & age_group==5,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
		,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (1) 4,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month for age 5-14: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month_Age5,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month_Age5.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age5.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age5.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age5.tif", replace
	
twoway (line mx_1000 month_no if month_no <= 85 & age_group==15,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
	,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (1) 10,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month for age 15-49: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month_Age15,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month_Age15.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age15.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age15.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age15.tif", replace

twoway (line mx_1000 month_no if month_no <= 85 & age_group==50,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
	,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (5) 35,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month for age 50-64: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month_Age50,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month_Age50.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age50.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age50.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age50.tif", replace	


twoway (line mx_1000 month_no if month_no <= 85 & age_group==65,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
		,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (10) 120,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month for age 65+: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month_Age65,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month_Age65.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age65.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age65.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month_Age65.tif", replace
	

	
/* look at mortality rates by month */
use "${data}/${sitename}_RawCensoredEpisodes_month_age_split", clear
strate year month, output("${data}/${sitename}_py_mx_month",replace) nolist
use "${data}/${sitename}_py_mx_month", clear
merge m:1 year month using "${data}/year_month_month_no"
format _Y %9.0g

replace _Rate = _Rate
replace _Lower = _Lower
replace _Upper = _Upper
rename _D Deaths
rename _Y PersonDays  //exposure is in days
rename _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
* correct for DAYS time scale
gen PersonYears=PersonDays/365.25
egen TotD = sum(Deaths)
egen TotPY = sum(PersonYears) //convert exposure from days to years
gen mx_1000 = (Deaths/PersonYears)*1000
gen lb_mx_1000 = Lower95Mx *1000 *365.25
gen ub_mx_1000 = Upper95Mx *1000 *365.25
gen centreid = "${sitename}"
save "${data}/${sitename}_py_mx_month",replace

use "${data}/${sitename}_py_mx_month", clear
twoway (scatter  mx_1000 month if year == 2015, mcolor(black) lcolor(black) recast(connected) lpattern(solid)) ///
		(scatter  mx_1000 month if year == 2016,  mcolor(blue) lcolor(blue) recast(connected) lpattern(solid)) ///
	(scatter  mx_1000 month if year == 2017, mcolor(green) lcolor(green) recast(connected) lpattern(solid)) ///
	(scatter  mx_1000 month if year == 2018, mcolor(magenta) lcolor(magenta) recast(connected) lpattern(solid)) ///
	(scatter  mx_1000 month if year == 2019, mcolor(orange) lcolor(orange) recast(connected) lpattern(solid)) ///
	(scatter  mx_1000 month if year == 2020, mcolor(maroon) lcolor(maroon) recast(connected) lpattern(solid)) ///
	(scatter  mx_1000 month if year == 2021, mcolor(sand) lcolor(sand) recast(connected) lpattern(solid)) ///
	,xlabel(1 "Jan" ///
			2 "Feb" ///
			3 "Mar" ///
			4 "Apr" ///
			5 "May" ///
			6 "Jun" ///
			7 "Jul" ///
			8 "Aug" ///
			9 "Sep" ///
			10 "Oct" ///
			11 "Nov" ///
			12 "Dec", grid angle(0)) ///
	ylabel(0 (2) 16,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
		legend(label(1 "2015") label(2 "2016") ///
		label(3 "2017") label(4 "2018") label(5 "2019") ///
		label(6 "2020") label(7 "2021") ///
		region(lwidth(0) lcolor(white)) rows(2) position(12) ///
		size(small) ring(0)) ///
	title("Mortality by month: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month.tif", replace
	

twoway (rspike ub_mx_1000 lb_mx_1000 month_no if month_no <= 85, lcolor(gs7)) ///
	(scatter mx_1000 month_no if month_no <= 85,mfcolor(gs7) mlcolor(gs7) ) ///
	,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (2) 20,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month2,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month2.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month2.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month2.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month2.tif", replace

twoway (line mx_1000 month_no if month_no <= 85,recast(connected) msymbol(x) lcolor(gs7) mfcolor(gs7) mlcolor(gs7)) ///
	,xlabel(1 "2015-Jan" ///
			4 "2015-Apr" ///
			7 "2015-Jul" ///
			10 "2015-Oct" ///
			13 "2016-Jan" ///
			16 "2016-Apr" ///
			19 "2016-Jul" ///
			22 "2016-Oct" ///
			25 "2017-Jan" ///
			28 "2017-Apr" ///
			31 "2017-Jul" ///
			34 "2017-Oct" ///
			37 "2018-Jan" ///
			40 "2018-Apr" ///
			43 "2018-Jul" ///
			46 "2018-Oct" ///
			49 "2019-Jan" ///
			52 "2019-Apr" ///
			55 "2019-Jul" ///
			58 "2019-Oct" ///
			61 "2020-Jan" ///
			64 "2020-Apr" ///
			67 "2020-Jul" ///
			70 "2020-Oct" ///
			73 "2021-Jan" ///
			76 "2021-Apr" ///
			79 "2021-Jul" ///
			82 "2021-Oct" ///
			85 "2022-Jan" ///
			, grid angle(90)) ///
	ylabel(0 (2) 20,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3)) ///
	xtitle("Month",height(3) ) ///
	legend(off) ///
	title("Mortality by month: `site'") ///
	graphregion(color(white)) name(${sitename}_Mx_By_Month3,replace) 
	graph save "${graphs}/${sitename}_Mx_By_Month3.gph", replace
	graph export "${graphs}/${sitename}_Mx_By_Month3.pdf", replace
	graph export "${graphs}/${sitename}_Mx_By_Month3.png", replace
	graph export "${graphs}/${sitename}_Mx_By_Month3.tif", replace
	
	
	

