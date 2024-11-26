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
	
//load STSET data
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear

//split by age and calender year
stsplit agegrp, at(0 1 5 (5)90)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year
tab agegrp

count if _t0 >= _t
drop if _t0 >= _t

//compute adult LE by sex and period and store along with CI's in new dataset 
tempname stciout
postfile `stciout'  sex year N e se elb eub using "${data}/${sitename}_LE_est", replace 
forvalues i=1(1)2 {						//i=male
	forvalues j=2015(1)2021 {			//j=year 
			stci if sex==`i' & year==`j',  rmean     // mean survival time restricted to the longest follow-up time
			local e=r(rmean)
			local se=r(se)
			local eub=r(ub)
			local elb=r(lb)
			local N=r(N_sub)
			post `stciout' (`i') (`j') (`N') (`e') (`se') (`elb') (`eub')
	}
}
postclose `stciout'

use "${data}/${sitename}_LE_est",clear
lab var N "Number of subjects"
lab var e "Years lived"
lab var se "Standard error for e"
lab var elb "Years lived, lower bound"
lab var eub "Years lived, uppper bound"
sort sex year
list, clean noobs
save "${data}/${sitename}_LE_est", replace
outsheet using "${data}/${sitename}_LE_est.csv", comma replace


//another approach
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear

//split by age and calender year
stsplit agegrp, at(0 1 5 (5)90)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year
tab agegrp

count if _t0 >= _t
drop if _t0 >= _t
* survivor functions by sex and year
sts list, at(0 1 5 (5)90) by(sex year) saving("${data}/${sitename}_surv", replace) 

use "${data}/${sitename}_surv", replace
rename time agegrp
drop begin fail std_err lb ub

* Standard life table terminology is used:
* l=proportion surviving to age x, L= person-years in age interval, T= person years above exact age x
rename surv l
sort sex year agegrp
by sex year: gen L=(5*l[_n+1]) + (2.55 * (l-l[_n+1])) if _n <_N	//PY (L) in the age-interval 
by sex year: egen T=total(L) // T, T0=total PY lived between ages 0 and upper bound
by sex year: replace T=T[_n-1]-L[_n-1] if _n>=2 //PY above exact age x 
by sex year: replace T= . if _n ==_N //don't need this for upper age interval 
gen e=T/l 

list sex year age l L T e

save "${data}/${sitename}_LE_est2", replace

use "${data}/${sitename}_LE_est2", clear
reshape wide l L T e, i(sex agegrp) j(year)
save "${data}/${sitename}_LE_est_wide", replace

//Life expectancy at age 15
use "${data}/${sitename}_RawCensoredEpisodes_st_ready", clear

//split by age and calender year
stsplit agegrp, at(0 1 5 (5)90)
stsplit year, after((mdy(01,01,$yearstart)))  every(1)
replace year = year + $yearstart
tab year
tab agegrp

count if _t0 >= _t
drop if _t0 >= _t
* survivor functions by sex and year
sts list, at(15 (5)90) by(sex year) saving("${data}/${sitename}_surv15", replace) 

use "${data}/${sitename}_surv15", replace
rename time agegrp
drop begin fail std_err lb ub

* Standard life table terminology is used:
* l=proportion surviving to age x, L= person-years in age interval, T= person years above exact age x
rename surv l
sort sex year agegrp
by sex year: gen L=(5*l[_n+1]) + (2.55 * (l-l[_n+1])) if _n <_N	//PY (L) in the age-interval 
by sex year: egen T=total(L) // T, T0=total PY lived between ages 0 and upper bound
by sex year: replace T=T[_n-1]-L[_n-1] if _n>=2 //PY above exact age x 
by sex year: replace T= . if _n ==_N //don't need this for upper age interval 
gen e=T/l 

list sex year age l L T e

save "${data}/${sitename}_LE_est15", replace

use "${data}/${sitename}_LE_est15", clear
reshape wide l L T e, i(sex agegrp) j(year)
save "${data}/${sitename}_LE_est_wide15", replace

list sex e* if agegrp==15

