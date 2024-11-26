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

stdescribe

//create 5 year age groups
stsplit agegrp, at(0(5)100)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year

//create 5 year age groups
label define agrps 0 "0-4" 5 "5-9" 10 "10-14" 15 "15-19" 20 "20-24" 25 "25-29" ///
	30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49" 50 "50-54" 55 "55-59" 60 "60-64" ///
	65 "65-69" 70 "70-74" 75 "75-79" 80 "80-84" 85 "85-89" 90 "90-94" 95 "95-99" 100 "100+" 
label values agegrp agrps

//create 10 year age groups
recode agegrp (0/4=0) (5/14=5) (15/24=15) (25/34=25) ///
	(35/44=35) (45/54=45) (55/64=55) (65/74=65) ///
	(75/max=75), gen(agegrp10)

//create standard WHO  age groups
recode agegrp (0/4=0) (5/14=5) (15/49=15) (50/64=50) ///
	(65/max=65), gen(agegrp_who)

strate year sex agegrp, output("${data}/${sitename}_py_mx_sex_age",replace) nolist
use "${data}/${sitename}_py_mx_sex_age", clear

format _Y %9.0g

replace _Rate = _Rate
replace _Lower = _Lower
replace _Upper = _Upper
rename _D Deaths
rename _Y PersonYears //exposure is in days
rename _Rate Mx
rename _Lower Lower95Mx
rename _Upper Upper95Mx
egen TotD = sum(Deaths)
egen TotPY = sum(PersonYears) //convert exposure from days to years
gen mx_1000 = (Deaths/PersonYears)*1000
gen lb_mx_1000 = Lower95Mx *1000 
gen ub_mx_1000 = Upper95Mx *1000 
gen centreid = "${sitename}"
gen male = sex == 1
replace male = male * PersonYears
gen female = sex == 2
replace female = female * PersonYears
save "${data}/${sitename}_py_mx_sex_age",replace

//create population pyramids
use "${data}/${sitename}_py_mx_sex_age", clear
collapse (sum) male female, by(year agegrp)
sort year agegrp
bys year: gen agegrp_no = _n
save "${data}/${sitename}_pop_by_gender_5yr_agegrp", replace

forvalues i=2015/2022 {
use "${data}/${sitename}_pop_by_gender_5yr_agegrp", clear
keep if year == `i'
gen py_male_female = male + female
egen male_total = total(male)
egen female_total = total(female)
gen per_male = male / male_total * 100
gen per_female = female / female_total * 100
replace male = -male
gen zero = -8000
save "${data}/${sitename}_pop_by_gender_5yr_agegrp_`i'", replace
twoway (bar male agegrp_no, horizontal fcolor(blue) lcolor(blue) lwidth(vthin)) ///
	(bar female agegrp_no, horizontal fc(maroon) lc(maroon) lwidth(vthin)) ///
	(scatter agegrp_no zero, mlabel(agegrp) mlabcolor(black) msymbol(none)) ///
,title("{bf:`i'}", col(green) size(*.8)) ///
xtitle("Population", size(small)) ytitle("Age", size(small)) ///
yscale(noline) ///
ylabel(,nogrid) ///
xscale(range(-7000 7000)) ///
xlabel(-6000 "6000" -4000 "4000"  -2000 "2000" 0(2000)7000, labsize(small)) ///
ylabel("") ///
legend(off) text(21 -1000 "Male", size(small)) text(21 1000 "Female", size(small)) ///
graphregion(color(white)) name(pramid`i',replace)
		graph save "${graphs}/${sitename}_pramid`i'.gph", replace
		graph export "${graphs}/${sitename}_pramid`i'.pdf", replace
		graph export "${graphs}/${sitename}_pramid`i'.png", replace
		graph export "${graphs}/${sitename}_pramid`i'.tif", replace
}

graph combine  "${graphs}/${sitename}_pramid2015.gph" ///
"${graphs}/${sitename}_pramid2016.gph" ///
"${graphs}/${sitename}_pramid2017.gph" ///
"${graphs}/${sitename}_pramid2019.gph" ///
"${graphs}/${sitename}_pramid2020.gph" ///
"${graphs}/${sitename}_pramid2021.gph", ///
r(2) iscale(*.7) imargin(0 1 2 0) scheme(s1color) 
graph export "${graphs}/${sitename}_pramids2015to2021.pdf", replace
graph export "${graphs}/${sitename}_pramids2015to2021.pdf", replace
graph export "${graphs}/${sitename}_pramids2015to2021.png", replace
graph export "${graphs}/${sitename}_pramids2015to2021.tif", replace



forvalues i=2015/2022 {
use "${data}/${sitename}_pop_by_gender_5yr_agegrp_`i'", clear
if `i' == 2015 {
	save "${data}/${sitename}_pop_by_gender_5yr_agegrp_all", replace
	}
else {
	append using "${data}/${sitename}_pop_by_gender_5yr_agegrp_all"
	save "${data}/${sitename}_pop_by_gender_5yr_agegrp_all", replace
	}
}
