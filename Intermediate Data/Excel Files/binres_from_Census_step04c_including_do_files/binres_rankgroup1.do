insheet using C:\Users\es2427\Research\ZIPsep30/Intermediate Data/Excel Files/binres_from_Census_step04c_including_do_files/binres_rankgroup1.csv

label variable fitrank_by1 "fitrank; pf_wm==0"
label variable fitrank_by2 "fitrank; pf_wm==1"
label variable fity_by1 "fity; pf_wm==0"
label variable fity_by2 "fity; pf_wm==1"

twoway (scatter fity_by1 fitrank_by1, mcolor(blue%60) lcolor(blue%60) msymbol(Sh)) (scatter fity_by2 fitrank_by2, mcolor(red%20) lcolor(red%20) msymbol(C)) (function 0*x^2+.0190711300676847*x+2.788466739740426, range(-.2597418905953404 .2909300235115876) lcolor(blue%60)) (function 0*x^2+.099265827860898*x+2.390114319671212, range(-.2563760839033835 .2811809788513843) lcolor(red%20)), graphregion(fcolor(white))  xtitle(fitrank) ytitle(fity) legend(lab(1 pf_wm=0) lab(2 pf_wm=1) order(1 2)) scheme(s1color) xlabel(-.3(.1).3, labsize(small)) ylabel(,labsize(small)) xtitle("Neighborhood price rank",size(small)) ytitle("Conditional mean",size(small)) title("B. Class rank year 1",size(small)) legend(order(1 "Other high school" 2 "Private feeder") size(*.6))
