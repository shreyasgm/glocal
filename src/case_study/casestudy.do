cd "/Users/josemoralesarilla/Library/CloudStorage/Dropbox/PhD/Research/CID/GlocalData"

// * GID 1 Level * //

use "Satellite Imagery Aggregations/data/aggregations/imagery_aggregations/annualized_level_1.dta", clear

encode GID_1, gen(gid1_num)
xtset gid1_num year
gen GID_0 = substr(GID_1, 1, 3)

by gid1_num: gen pop = population_count[70]
by gid1_num: gen dens = population_density[70]

keep if year == 2019

keep GID* gid1_num urban_time_to_large_cities_mins viirs pop dens

gen NL_pc = viirs / pop * 1000000

gen ihs_NL_pc = asinh(NL_pc)
gen ihs_prox = asinh(- urban_time_to_large_cities_mins)
gen ihs_pop = asinh(pop)
gen ihs_dens = asinh(dens)

drop if ihs_prox == .

twoway (scatter ihs_NL_pc ihs_prox, msize(tiny)) ///
		(lowess ihs_NL_pc ihs_prox), legend(off) ///
		xtitle("Proximity of urban areas to a large city (IHS)") ///
		ytitle("Nighttime light radiance per million inhabitants (IHS)")
graph export NL_Prox.png, replace
		
twoway (scatter ihs_dens ihs_prox, msize(tiny)) ///
		(lowess ihs_dens ihs_prox), legend(off) ///
		xtitle("Proximity of urban areas to a large city (IHS)") ///
		ytitle("Population density (IHS)")		
graph export Dens_Prox.png, replace
		
cap erase casestudy.tex
cap erase casestudy.txt		
reghdfe ihs_NL_pc ihs_prox, absorb(GID_0)
outreg2 using casestudy.tex, append addtext(Fixed Effects, GID0)
reghdfe ihs_NL_pc ihs_prox ihs_dens, absorb(GID_0)
outreg2 using casestudy.tex, append addtext(Fixed Effects, GID0)	

encode GID_0, gen(gid0)
		
qui reg ihs_NL_pc i.gid0
predict ihs_NL_pc_res0, resid
qui reg ihs_prox i.gid0
predict ihs_prox_res0, resid
qui reg ihs_dens i.gid0
predict ihs_dens_res0, resid		

qui su ihs_prox_res0, d
local c = r(p25)
local t = r(p75)
mediate (ihs_NL_pc_res0) (ihs_dens_res0) (ihs_prox_res0, continuous(`c' `t'))
		
		
// * GID 2 Level * //	
		
use "Satellite Imagery Aggregations/data/aggregations/imagery_aggregations/annualized_level_2.dta", clear

encode GID_2, gen(gid2_num)
xtset gid2_num year
gen GID_0 = substr(GID_2, 1, 3)

split GID_2, parse(".")
gen GID_1 = GID_21 + "." + GID_22
drop GID_23 GID_22 GID_21

by gid2_num: gen pop = population_count[70]
by gid2_num: gen dens = population_density[70]

keep if year == 2019

keep GID* gid2_num urban_time_to_large_cities_mins viirs pop dens

gen NL_pc = viirs / pop * 1000000

gen ihs_NL_pc = asinh(NL_pc)
gen ihs_prox = asinh(- urban_time_to_large_cities_mins)
gen ihs_pop = asinh(pop)
gen ihs_dens = asinh(dens)

drop if ihs_prox == .

reghdfe ihs_NL_pc ihs_prox, absorb(GID_0)
outreg2 using casestudy.tex, append	 addtext(Fixed Effects, GID0)	
reghdfe ihs_NL_pc ihs_prox ihs_dens, absorb(GID_0)
outreg2 using casestudy.tex, append	 addtext(Fixed Effects, GID0)	
reghdfe ihs_NL_pc ihs_prox, absorb(GID_1)
outreg2 using casestudy.tex, append	 addtext(Fixed Effects, GID1)	
reghdfe ihs_NL_pc ihs_prox ihs_dens, absorb(GID_1)
outreg2 using casestudy.tex, append	 addtext(Fixed Effects, GID1)	

encode GID_0, gen(gid0)
encode GID_1, gen(gid1)

qui reg ihs_NL_pc i.gid1
predict ihs_NL_pc_res1, resid
qui reg ihs_prox i.gid1
predict ihs_prox_res1, resid
qui reg ihs_dens i.gid1
predict ihs_dens_res1, resid

qui su ihs_prox_res1, d
local c = r(p25)
local t = r(p75)
mediate (ihs_NL_pc_res1) (ihs_dens_res1) (ihs_prox_res1, continuous(`c'  `t'))







