insheet using C:\Users\es2427\Research\ZIPsep30/Intermediate Data/Excel Files/binres_from_Census_step04c_including_do_files/binres_final_tier2.csv

label variable fitrank_by1 "fitrank; pf_wm==0"
label variable fitrank_by2 "fitrank; pf_wm==1"
label variable fity_by1 "fity; pf_wm==0"
label variable fity_by2 "fity; pf_wm==1"

twoway (scatter fity_by1 fitrank_by1, mcolor(blue%60) lcolor(blue%60) msymbol(Sh)) (scatter fity_by2 fitrank_by2, mcolor(red%20) lcolor(red%20) msymbol(C)) (function 0*x^2+.0006075490519527*x+.034914102754786, range(-.2642493824313833 .2865202669676243) lcolor(blue%60)) (function 0*x^2+.1674771243250013*x+.2264587939230069, range(-.2597331420715112 .2755584311874016) lcolor(red%20)), graphregion(fcolor(white))  xtitle(fitrank) ytitle(fity) legend(lab(1 pf_wm=0) lab(2 pf_wm=1) order(1 2)) scheme(s1color) xlabel(-.3(.1).3, labsize(small)) ylabel(,labsize(small)) xtitle("Neighborhood price rank",size(small)) ytitle("Conditional mean",size(small)) title("A. Selective final club",size(small)) legend(order(1 "Other high school" 2 "Private feeder") size(*.6))
