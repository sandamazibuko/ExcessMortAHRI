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

use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear

//create 5 year age groups
stsplit agegrp, at(0(5)100)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year

label define agrps 0 "0-4" 5 "5-9" 10 "10-14" 15 "15-19" 20 "20-24" 25 "25-29" ///
	30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49" 50 "50-54" 55 "55-59" 60 "60-64" ///
	65 "65-69" 70 "70-74" 75 "75-79" 80 "80-84" 85 "85-89" 90 "90-94" 95 "95-99" 100 "100+" 
label values agegrp agrps

//create standard WHO  age groups
recode agegrp (0/4=0) (5/14=5) (15/49=15) (50/64=50) ///
	(65/max=65), gen(agegrp_who)
	
strate year agegrp_who, output("${data}/${sitename}_py_mx_age",replace) nolist
use "${data}/${sitename}_py_mx_age", clear
format _Y %9.0g
rename _D Deaths
rename _Y PersonYears
rename _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
egen TotD = sum(Deaths)
egen TotPY = sum(PersonYears) 
gen mx_1000 = (Deaths/PersonYears)*1000
gen lb_mx_1000 = Lower95Mx *1000 
gen ub_mx_1000 = Upper95Mx *1000 
gen centreid = "${sitename}"
save "${data}/${sitename}_py_mx_age",replace

use "${data}/${sitename}_py_mx_age", clear 
drop if year > $yearend
twoway (scatter mx_1000 year if agegrp==0,mfcolor(gs7) mlcolor(gs7)) ///
	(scatter mx_1000 year if agegrp==5,mfcolor(blue) mlcolor(blue)) ///
	(scatter mx_1000 year if agegrp==15,mfcolor(green) mlcolor(green)) ///
	(scatter mx_1000 year if agegrp==50,mfcolor(red) mlcolor(red)) ///
	(scatter mx_1000 year if agegrp==65,mfcolor(navy) mlcolor(navy)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (10) 60,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(cols(6) position(12) ///
			order(1 "0-4 years" 2 "5-14 years" 3 "15-49" 4 "50-64 years" 5 "65+ years") ///
			region(lwidth(0) lcolor(white)) ring(1) size(small)) ///
	title("Overall Mortality: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_agegrp_year,replace) 
	graph save "${graphs}/${sitename}_mx_agegrp_year.gph", replace
	graph export "${graphs}/${sitename}_mx_agegrp_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_agegrp_year.png", replace
	graph export "${graphs}/${sitename}_mx_agegrp_year.tif", replace
	

twoway (rspike ub_mx_1000 lb_mx_1000 year if agegrp==0, lcolor(gs4)) ///
	(scatter mx_1000 year if agegrp==0,mfcolor(gs4) mlcolor(gs4)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 10,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Mortality for 0-4 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_0to4_year,replace) 
	graph save "${graphs}/${sitename}_mx_0to4_year.gph", replace
	graph export "${graphs}/${sitename}_mx_0to4_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_0to4_year.png", replace
	graph export "${graphs}/${sitename}_mx_0to4_year.tif", replace
	
twoway (rspike ub_mx_1000 lb_mx_1000 year if agegrp==5, lcolor(gs4)) ///
	(scatter mx_1000 year if agegrp==5,mfcolor(gs4) mlcolor(gs4)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 3,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Mortality for 5-14 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_5to14_year,replace) 
	graph save "${graphs}/${sitename}_mx_5to14_year.gph", replace
	graph export "${graphs}/${sitename}_mx_5to14_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_5to14_year.png", replace
	graph export "${graphs}/${sitename}_mx_5to14_year.tif", replace	
	
twoway (rspike ub_mx_1000 lb_mx_1000 year if agegrp==15, lcolor(gs4)) ///
	(scatter mx_1000 year if agegrp==15,mfcolor(gs4) mlcolor(gs4)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 10,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Mortality for 15-49 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_15to49_year,replace) 
	graph save "${graphs}/${sitename}_mx_15to49_year.gph", replace
	graph export "${graphs}/${sitename}_mx_15to49_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_15to49_year.png", replace
	graph export "${graphs}/${sitename}_mx_15to49_year.tif", replace	

twoway (rspike ub_mx_1000 lb_mx_1000 year if agegrp==50, lcolor(gs4)) ///
	(scatter mx_1000 year if agegrp==50,mfcolor(gs4) mlcolor(gs4)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (2) 24,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Mortality for 50-64 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_50to64_year,replace) 
	graph save "${graphs}/${sitename}_mx_50to64_year.gph", replace
	graph export "${graphs}/${sitename}_mx_50to64_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_50to64_year.png", replace
	graph export "${graphs}/${sitename}_mx_50to64_year.tif", replace

twoway (rspike ub_mx_1000 lb_mx_1000 year if agegrp==65, lcolor(gs4)) ///
	(scatter mx_1000 year if agegrp==65,mfcolor(gs4) mlcolor(gs4)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (5) 85,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Mortality for 65+ year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_65_year,replace) 
	graph save "${graphs}/${sitename}_mx_65_year.gph", replace
	graph export "${graphs}/${sitename}_mx_65_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_65_year.png", replace
	graph export "${graphs}/${sitename}_mx_65_year.tif", replace

//mortality rates by year, age and sex
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear

//create 5 year age groups
stsplit agegrp, at(0(5)100)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year

label define agrps 0 "0-4" 5 "5-9" 10 "10-14" 15 "15-19" 20 "20-24" 25 "25-29" ///
	30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49" 50 "50-54" 55 "55-59" 60 "60-64" ///
	65 "65-69" 70 "70-74" 75 "75-79" 80 "80-84" 85 "85-89" 90 "90-94" 95 "95-99" 100 "100+" 
label values agegrp agrps

//create standard WHO  age groups
recode agegrp (0/4=0) (5/14=5) (15/49=15) (50/64=50) ///
	(65/max=65), gen(agegrp_who)
	
strate year sex agegrp_who, output("${data}/${sitename}_py_mx_sex_age",replace) nolist
use "${data}/${sitename}_py_mx_sex_age", clear
format _Y %9.0g
rename _D Deaths
rename _Y PersonYears
rename _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
egen TotD = sum(Deaths)
egen TotPY = sum(PersonYears) 
gen mx_1000 = (Deaths/PersonYears)*1000
gen lb_mx_1000 = Lower95Mx *1000 
gen ub_mx_1000 = Upper95Mx *1000 
gen centreid = "${sitename}"
save "${data}/${sitename}_py_mx_sex_age",replace

//plot mortality rates by year, age and sex
drop if year > $yearend
capture drop xaxis*             
gen xaxisw=year+0.085

twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1 & agegrp==0,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1 & agegrp==0,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2 & agegrp==0,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2 & agegrp==0,mfcolor(white) mlcolor(blue)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 10,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Mortality for 0-4 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_0to4_year2,replace) 
	graph save "${graphs}/${sitename}_mx_0to4_year2.gph", replace
	graph export "${graphs}/${sitename}_mx_0to4_year2.pdf", replace
	graph export "${graphs}/${sitename}_mx_0to4_year2.png", replace
	graph export "${graphs}/${sitename}_mx_0to4_year2.tif", replace

twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1 & agegrp==5,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1 & agegrp==5,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2 & agegrp==5,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2 & agegrp==5,mfcolor(white) mlcolor(blue)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 5,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Mortality for 5-14 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_5to14_year2,replace) 
	graph save "${graphs}/${sitename}_mx_5to14_year2.gph", replace
	graph export "${graphs}/${sitename}_mx_5to14_year2.pdf", replace
	graph export "${graphs}/${sitename}_mx_5to14_year2.png", replace
	graph export "${graphs}/${sitename}_mx_5to14_year2.tif", replace	
	

twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1 & agegrp==15,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1 & agegrp==15,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2 & agegrp==15,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2 & agegrp==15,mfcolor(white) mlcolor(blue)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (1) 10,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Mortality for 15-49 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_15to49_year2,replace) 
	graph save "${graphs}/${sitename}_mx_15to49_year2.gph", replace
	graph export "${graphs}/${sitename}_mx_15to49_year2.pdf", replace
	graph export "${graphs}/${sitename}_mx_15to49_year2.png", replace
	graph export "${graphs}/${sitename}_mx_15to49_year2.tif", replace	

twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1 & agegrp==50,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1 & agegrp==50,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2 & agegrp==50,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2 & agegrp==50,mfcolor(white) mlcolor(blue)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (5) 35,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Mortality for 50-64 year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_50to64_year2,replace) 
	graph save "${graphs}/${sitename}_mx_50to64_year2.gph", replace
	graph export "${graphs}/${sitename}_mx_50to64_year2.pdf", replace
	graph export "${graphs}/${sitename}_mx_50to64_year2.png", replace
	graph export "${graphs}/${sitename}_mx_50to64_year2.tif", replace

twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1 & agegrp==65,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1 & agegrp==65,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2 & agegrp==65,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2 & agegrp==65,mfcolor(white) mlcolor(blue)) ///
	,xlabel($yearstart (1) $yearend, grid angle(0)) ///
	ylabel(0 (10) 100,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Mortality for 65+ year olds: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_65_year2,replace) 
	graph save "${graphs}/${sitename}_mx_65_year2.gph", replace
	graph export "${graphs}/${sitename}_mx_65_year2.pdf", replace
	graph export "${graphs}/${sitename}_mx_65_year2.png", replace
	graph export "${graphs}/${sitename}_mx_65_year2.tif", replace

//combine graphs
graph combine "${graphs}/${sitename}_mx_0to4_year.gph" ///
"${graphs}/${sitename}_mx_5to14_year.gph" ///
"${graphs}/${sitename}_mx_15to49_year.gph" ///
"${graphs}/${sitename}_mx_50to64_year.gph" ///
"${graphs}/${sitename}_mx_65_year.gph", ///
r(2) iscale(*.8) imargin(0 0 0 0) scheme(s1color)
graph export "${graphs}/${sitename}_mx_age_year2.pdf", replace
graph export "${graphs}/${sitename}_mx_age_year2.pdf", replace
graph export "${graphs}/${sitename}_mx_age_year2.png", replace
graph export "${graphs}/${sitename}_mx_age_year2.tif", replace

graph combine "${graphs}/${sitename}_mx_0to4_year2.gph" ///
"${graphs}/${sitename}_mx_15to49_year2.gph" ///
"${graphs}/${sitename}_mx_50to64_year2.gph" ///
"${graphs}/${sitename}_mx_65_year2.gph", ///
r(2) iscale(*.8) imargin(0 0 0 0) scheme(s1color)
graph export "${graphs}/${sitename}_mx_age_sex_year.pdf", replace
graph export "${graphs}/${sitename}_mx_age_sex_year.pdf", replace
graph export "${graphs}/${sitename}_mx_age_sex_year.png", replace
graph export "${graphs}/${sitename}_mx_age_sex_year.tif", replace
