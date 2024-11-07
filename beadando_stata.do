*Előbeállítások:
set more off
global data "/Users/petermilan/Documents/Egyetem/BCE - GTK/Adatelemzés a tudományos gyakorlatban/Beadandó"
cd "$data"

*Parancsok:
cls
clear all
browse

*Adatok importálása az excel táblából:
import excel airbnb_listing_vienna.xlsx, first

*Adatok átalakítása:
gen foryear = 2022 - host_since
replace host_since = foryear
drop foryear

foreach v of varlist host_is_superhost host_has_profile_pic host_identity_verified{
	gen byte bin_`v' = 1 if `v' == "t"
	replace bin_`v' = 0 if `v' == "f"
}

foreach v of varlist host_response_time neighbourhood_cleansed property_type room_type{
	egen cat_`v' = group(`v'), label(cat_`v', replace)
}
*Megjegyzések:
*host_response_time: ib4.cat_host_response_time (within an hour)
*neighbourhood_cleansed: ib9.cat_neighbourhood_cleansed (Innere Stadt)
*property_type: ib10.cat_property_type (Entire rental unit)
*room_type: ib1.cat_room_type (Entire home/apt)

gen popularity = number_of_reviews * (review_scores_rating + review_scores_accuracy + review_scores_cleanliness + review_scores_checkin + review_scores_communication + review_scores_location + review_scores_value)

*Labeling:
label variable id "ID"
label variable name "Szállás neve"
label variable host_name "Szállásadó neve"
label variable host_since "Ennyi éve szállásadó"
label variable host_response_time "Szállásadó válaszolási ideje"
label variable host_response_rate "Szállásadó válaszolási aránya"
label variable host_acceptance_rate "Szállásadó elfogadási aránya"
label variable host_is_superhost "Superhost"
label variable host_has_profile_pic "Van profilképe"
label variable host_identity_verified "Azonosított"
label variable neighbourhood_cleansed "Környék"
label variable property_type "Szállás típusa"
label variable room_type "Szoba típusa"
label variable accommodates "Férőhelyek száma"
label variable bathrooms "Fürdőszobák száma"
label variable bedrooms "Hálószobák száma"
label variable beds "Ágyak száma"
label variable price "Ár"
label variable minimum_nights "Minimum éjszakák száma"
label variable maximum_nights "Maximum éjszakák száma"
label variable number_of_reviews "Érdékelések száma"
label variable popularity "Népszerűség"

*Leíró statisztika:
summarize host_since host_response_rate host_acceptance_rate accommodates bathrooms bedrooms beds price minimum_nights maximum_nights number_of_reviews review_scores_rating review_scores_accuracy review_scores_cleanliness review_scores_checkin review_scores_communication review_scores_location review_scores_value

*Hisztogramok:
graph bar (count), over(host_response_time, descending)
graph hbar (count), over(neighbourhood_cleansed, sort(1) descending)
graph hbar (count), over(property_type, sort(1)descending)
graph bar (count), over(room_type, descending)

*Kördiagramok:
graph pie, over(host_is_superhost) plabel(_all percent)
graph pie, over(host_has_profile_pic) plabel(_all percent)
graph pie, over(host_identity_verified) plabel(_all percent)

*Korrelációmátrix:
corr host_since accommodates bathrooms bedrooms beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_has_profile_pic bin_host_identity_verified

*Pontdiagramok:
graph twoway scatter bedrooms beds
graph twoway scatter bedrooms bathrooms

*Regresszió:
*Teljes modell:
quietly reg popularity host_since accommodates bathrooms bedrooms beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_has_profile_pic bin_host_identity_verified cat_host_response_time cat_neighbourhood_cleansed  cat_property_type cat_room_type
estat ic

*Export excelbe:
*putexcel set valami
*putexcel A1 = etable

*1.modell(-accommodates; -bin_host_has_profile_pic, -cat_property_type; -cat_room_type):
reg popularity host_since bathrooms bedrooms beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_identity_verified cat_host_response_time cat_neighbourhood_cleansed
estat ic

*2.modell (c.bedrooms#c.beds):
reg popularity host_since bathrooms c.bedrooms#c.beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_identity_verified cat_host_response_time cat_neighbourhood_cleansed
estat ic

*3.modell (4.cat_host_response_time):
reg popularity host_since bathrooms c.bedrooms#c.beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_identity_verified 4.cat_host_response_time cat_neighbourhood_cleansed
estat ic

*4.modell (ib9.cat_neighbourhood_cleansed):
reg popularity host_since bathrooms c.bedrooms#c.beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_identity_verified 4.cat_host_response_time 9.cat_neighbourhood_cleansed
estat ic

*Hisztogramok a logaritmizáláshoz:
label variable ln_popularity "ln(Népszerűség)"
histogram popularity, bin(50)
gen ln_popularity = ln(popularity)
histogram ln_popularity, bin(50)

*5.modell (loglin modell):
reg ln_popularity host_since bathrooms c.bedrooms#c.beds price minimum_nights maximum_nights host_response_rate host_acceptance_rate bin_host_is_superhost bin_host_identity_verified 4.cat_host_response_time 9.cat_neighbourhood_cleansed
estat ic

*Export excelbe:
*putexcel set vegsomodell
*putexcel A1 = etable

*RESET teszt:
estat ovtest

*Multikollinearitás:
estat vif

*Homoszkedaszticitás:
rvfplot
estat hettest

