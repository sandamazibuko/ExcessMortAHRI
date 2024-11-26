
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
	
	
/* person years, number of deaths and overall mortality*/
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year
strate year, output("${data}/${sitename}_py_mx",replace) nolist
use "${data}/${sitename}_py_mx", clear
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
save "${data}/${sitename}_py_mx",replace

//plot of person years
drop if year > $yearend
format PersonYears %9.0fc
sum PersonYears 
local max= r(max)
local min= r(min)
local step = `max'/10

twoway (bar PersonYears year, barw(.4) fcolor(dkgreen) lcolor(dkgreen) lwidth(vthin)) ///
	(scatter PersonYears year, msymbol(none) mlabel(PersonYears) mlabposition(12)) ///
	,xlabel(2015 (1) 2021, grid angle(0)) ///
	ylabel(0 (`step') `max',format(%9.0fc) grid angle(0)) ///
	ytitle("Person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("`site': Person years") ///
	graphregion(color(white)) name(${sitename}_PY,replace) 
	graph save "${graphs}/${sitename}_PY.gph", replace
	graph export "${graphs}/${sitename}_PY.pdf", replace
	graph export "${graphs}/${sitename}_PY.png", replace
	graph export "${graphs}/${sitename}_PY.tif", replace	

///graph of deaths
sum Deaths
local max= r(max)
local min= r(min)
local step = `max'/10

twoway (bar Deaths year, barw(.5) fcolor(red) lcolor(red) lwidth(vthin)) ///
	(scatter Deaths year, msymbol(none) mlabel(Deaths) mlabposition(12)) ///
	,xlabel(2015 (1) 2021, grid angle(0)) ///
	ylabel(0 (`step') `max',format(%9.0fc) grid angle(0)) ///
	ytitle("Number of deaths",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("`site': Number of deaths") ///
	graphregion(color(white)) name(${sitename}_Dx,replace) 
	graph save "${graphs}/${sitename}_Dx.gph", replace
	graph export "${graphs}/${sitename}_Dx.pdf", replace
	graph export "${graphs}/${sitename}_Dx.png", replace
	graph export "${graphs}/${sitename}_Dx.tif", replace	
	
//plot overall mortality
twoway (rspike ub_mx_1000 lb_mx_1000 year, lcolor(gs4)) ///
	(scatter mx_1000 year,mfcolor(gs4) mlcolor(gs4) lcolor(gs4) msize(*.8)) ///
	,xlabel(2015 (1) 2021, grid angle(0)) ///
	ylabel(0 (1) 14,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(off) ///
	title("Overall Mortality:`site'") ///
	graphregion(color(white)) name(${sitename},replace) 
	graph save "${graphs}/${sitename}_Mx.gph", replace
	graph export "${graphs}/${sitename}_Mx.pdf", replace
	graph export "${graphs}/${sitename}_Mx.png", replace
	graph export "${graphs}/${sitename}_Mx.tif", replace

/* person years, number of deaths and mortality rates by year and sex*/
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year
strate year sex, output("${data}/${sitename}_py_mx_sex",replace) nolist
use "${data}/${sitename}_py_mx_sex", clear
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
save "${data}/${sitename}_py_mx_sex",replace

//plot of person years by year and sex
drop if year > $yearend

capture drop xaxis*             
gen xaxisw=year+0.25
format PersonYears %9.0fc
sum PersonYears 
local max= r(max)
local min= r(min)
local step = `max'/10

	twoway (bar PersonYears year if sex==2, barw(.245) fcolor(dkgreen) lcolor(dkgreen) lwidth(vthin)) ///
		(bar PersonYears xaxisw if sex==1, barw(.245) fcolor(blue) lcolor(blue) lwidth(vthin)) ///
		(scatter PersonYears year if sex==2, msymbol(none) mlabel(PersonYears) mlabposition(1) msize(*0.8)) ///
		(scatter PersonYears xaxis if sex==1, msymbol(none) mlabel(PersonYears) mlabposition(1) msize(*0.8)) ///
		,xlabel(2015 (1) 2021.5, grid angle(0)) ///
		ylabel(0 (`step') `max',format(%9.0fc) grid angle(0)) ///
		ytitle("Person years",height(3) ) ///
		xtitle("Year",height(3) ) ///
		legend(order(1 "Female" 2 "Male" 3 "" 4 "") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
		title("`site': Person years") ///
		graphregion(color(white)) name(${sitename}_PY,replace) 
		graph save "${graphs}/${sitename}_PY_sex.gph", replace
		graph export "${graphs}/${sitename}_PY_sex.pdf", replace
		graph export "${graphs}/${sitename}_PY_sex.png", replace
		graph export "${graphs}/${sitename}_PY_sex.tif", replace	


//plot of deaths by year and sex
sum Deaths 
local max= r(max)
local min= r(min)
local step = `max'/10

	twoway (bar Deaths year if sex==2, barw(.245) fcolor(red) lcolor(red) lwidth(vthin)) ///
		(bar Deaths xaxisw if sex==1, barw(.245) fcolor(purple) lcolor(purple) lwidth(vthin)) ///
		(scatter Deaths year if sex==2, msymbol(none) mlabel(Deaths) mlabposition(1) msize(*0.8)) ///
		(scatter Deaths xaxis if sex==1, msymbol(none) mlabel(Deaths) mlabposition(1) msize(*0.8)) ///
		,xlabel(2015 (1) 2021.5, grid angle(0)) ///
		ylabel(0 (`step') `max',format(%9.0fc) grid angle(0)) ///
		ytitle("Number of deaths",height(3)) ///
		xtitle("Year",height(3) ) ///
		legend(order(1 "Female" 2 "Male" 3 "" 4 "") ///
			region(lwidth(0) lcolor(white)) position(12) ///
			ring(1) size(small) cols(4)) ///	
		title("`site': Number of deaths") ///
		graphregion(color(white)) name(${sitename}_Dx_sex,replace) 
		graph save "${graphs}/${sitename}_Dx_sex.gph", replace
		graph export "${graphs}/${sitename}_Dx_sex.pdf", replace
		graph export "${graphs}/${sitename}_Dx_sex.png", replace
		graph export "${graphs}/${sitename}_Dx_sex.tif", replace	
		
//plot of mortality rates by year and sex

capture drop xaxis*             
gen xaxisw=year+0.085
twoway (rspike ub_mx_1000 lb_mx_1000 year if sex==1,lcolor(gs4)) ///
	(scatter mx_1000 year if sex==1,mfcolor(gs4) mlcolor(gs4)) ///
	(rspike ub_mx_1000 lb_mx_1000 xaxisw  if sex==2,lcolor(blue)) ///
	(scatter mx_1000 xaxisw  if sex==2,mfcolor(white) mlcolor(blue)) ///
	,xlabel(2015 (1) 2021, grid angle(0)) ///
	ylabel(0 (1) 14,grid angle(0)) ///
	ytitle("Mortality per 1000 person years",height(3) ) ///
	xtitle("Year",height(3) ) ///
	legend(order(2 "Male" 1 "95% CI:Male" 4 "Female" 3 "95% CI:Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	title("Overall Mortality: `site'") ///
	graphregion(color(white)) name(${sitename}_mx_sex_year,replace) 
	graph save "${graphs}/${sitename}_mx_sex_year.gph", replace
	graph export "${graphs}/${sitename}_mx_sex_year.pdf", replace
	graph export "${graphs}/${sitename}_mx_sex_year.png", replace
	graph export "${graphs}/${sitename}_mx_sex_year.tif", replace
