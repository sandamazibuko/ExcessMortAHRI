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
	

global agecutofftop = 90			//upper age limit, can be set to a very high value (e.g.100)

global LEcompstart = 2019				//starting period for overall LE comparison (period of lowest observed LE)
global LEcompend = 2021				//end period for overall LE comparison (last period with data)


use "${data}/${sitename}_LE_est_wide", clear

// decompose life expectancy difference by age using formulas from 
// Arriaga EE. Measuring and explaining the change in life expectancies. 
// Demography 1984;21:83-96.

*Direct effect : l${LEcompstart} * (L${LEcompend}/l${LEcompend}-L${LEcompstart}/l${LEcompstart})
*Indirect effect and interaction term:  T${LEcompend}[_n+1]*(l${LEcompstart}/l${LEcompend} - l${LEcompstart}[_n+1]/l${LEcompend}[_n+1])
gen delta = l${LEcompstart} * (L${LEcompend}/l${LEcompend}-L${LEcompstart}/l${LEcompstart})+T${LEcompend}[_n+1]*(l${LEcompstart}/l${LEcompend} - l${LEcompstart}[_n+1]/l${LEcompend}[_n+1]) 
bysort sex : replace delta = l${LEcompstart}*(T${LEcompend}/l${LEcompend}-T${LEcompstart}/l${LEcompstart}) if agegrp==${agecutofftop}-5

* Code below is only to reassure that the deltas sum to the total life expectancy gap; of no further relevance & could be left out if so desired 
egen sumdeltaf =total(delta) if sex==2 			// caculate the sum of the deltas
egen sumdeltam =total(delta) if sex==1 
gen  legapinfem= e${LEcompend}-e${LEcompstart} if sex==2 & agegrp==0	//caculate the overall LE gap for the reference period
gen  legapinmal= e${LEcompend}-e${LEcompstart} if sex==1 & agegrp==0
di "Comparison of LE gain and the sum of the deltas (should be the same)"
list legapinfem sumdeltaf if  sex==2 & agegrp==0   
list legapinmal sumdeltam if  sex==1 & agegrp==0

assert round(legapinfem,0.05)==round(sumdeltaf,0.05) if sex==2 & agegrp==0  //program will be interrupted if the estimates differ
assert round(legapinmal,0.05)==round(sumdeltam,0.05) if sex==1 & agegrp==0  

*creating the graph
gen agegrp2=agegrp-0.6
gen agegrp3=agegrp+0.6

twoway (bar  delta agegrp2 if sex==1 & agegrp<=${agecutofftop}-5) ///
	   (bar  delta agegrp3 if sex==2 & agegrp<=${agecutofftop}-5) ///
	   ,ylabel(-1(0.2)1, format(%5.1f) angle(0) labsize(small)) ///
	   ytitle("Contribution, years",height(2) size(small))  ///
	   xtitle("Age group",height(3) size(small)) ///
	   xlabel(0 "<1" 1 "1-4" 5 "5-9" 10 "10-14" 15 "15-19" 20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" 45 "45-49" ///
	   50 "50-54" 55 "55-59" 60 "60-64" 65 "65-69" 70 "70-74" 75 "75-79" 80 "80-84" ///
	   85 "85-89", labsize(small) alternate labgap(*6)) ///
	   legend(order(1 "Male" 2 "Female") ///
		region(lwidth(0) lcolor(white)) position(12) ///
		ring(1) size(small) cols(4)) ///
	   title("Age contribution to LE changes") ///
	   subtitle("`site': ${LEcompstart} to ${LEcompend}") ///
	graphregion(color(white)) name(${sitename}_LE_Decomposition,replace) 
	graph save "${graphs}/${sitename}_LE_Decomposition.gph", replace
	graph export "${graphs}/${sitename}_LE_Decomposition.pdf", replace
	graph export "${graphs}/${sitename}_LE_Decomposition.png", replace
	graph export "${graphs}/${sitename}_LE_Decomposition.tif", replace
	