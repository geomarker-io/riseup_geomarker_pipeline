
.cran_packages <- c("cincy")
.inst <- .cran_packages %in% installed.packages()
if(any(!.inst)) {
  install.packages(.cran_packages[!.inst], repos = "http://cran.us.r-project.org")
}

library(tidyverse)
library(CODECtools)
library(cincy)

d <- readRDS("data/census_tract_identifier.rds")

#---------------------------------------------------------
# neighborhood
#---------------------------------------------------------
d.neighborhood <- d |> 
  select(-census_tract_id_2020) |> 
  add_neighborhood(vintage = "2010") |> 
  select(PAT_ENC_CSN_ID, neighborhood)

d <- d |> 
  left_join(d.neighborhood, by = "PAT_ENC_CSN_ID")

#---------------------------------------------------------
# tract_indices (2010 census tract id)
#---------------------------------------------------------
tract_indices <- readr::read_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0/tract_indices.csv")

d <- d |> 
  left_join(tract_indices, by=c("census_tract_id_2010" = "census_tract_id"))

#---------------------------------------------------------
# historical acs data (2010 or 2020 census tract id)
#---------------------------------------------------------
hh_acs_2019 <- readr::read_csv("https://codec-data.s3.amazonaws.com/hh_acs_measures/hh_acs_measures.csv") |> 
  filter(year == 2019) |> 
  select(-year, -census_tract_vintage) |> 
  rename_all(paste0, "_2019") |> 
  rename(census_tract_id = census_tract_id_2019)

d <- d |> 
  left_join(hh_acs_2019, by=c("census_tract_id_2010"="census_tract_id")) 

#---------------------------------------------------------
# AGS crime risk
# Hamilton county tracts only
# 2010 census tract vintage
#---------------------------------------------------------

if (file.exists("data-raw/AGS_crime_risk/ags_crime_risk.csv")){
  
  ags_crime <- read_csv("data-raw/AGS_crime_risk/ags_crime_risk.csv") |> 
    rename_all(~ paste0("ags_", .x)) |> 
    mutate(census_tract_id = as.character(ags_census_tract_id)) |> 
    select(-ags_census_tract_id)
  
  d <- d |> 
    left_join(ags_crime, by=c("census_tract_id_2010"="census_tract_id"))
  
} else {
  
  print("Cannot find data-raw/AGS_crime_risk/ags_crime_risk.csv. The data are proprietary product of Applied Geographic Solutions.")
  
}


# add column attributes
d <- d |>
  add_col_attrs(census_block_group_id_2010, 
                title = 'census block group id 2010', 
                description = '2010 census block group id'
                ) |>
  add_col_attrs(census_tract_id_2010, 
                title = 'census tract id 2010' , 
                description = '2010 census tract id'
                ) |>
  add_col_attrs(census_block_group_id_2020, 
                title = 'census block group id 2020' , 
                description = '2020 census block group id'
                ) |>
  add_col_attrs(census_tract_id_2020, 
                title = 'census tract id 2020' , 
                description = '2020 census tract id'
                ) |>
  add_col_attrs(neighborhood, 
                title = 'neighborhood' , 
                description = 'neighborhood in hamilton county'
                ) |>
  add_col_attrs(adi, 
                title = 'adi' , 
                description = 'neighborhood atlas area deprivation index'
                ) |>
  add_col_attrs(coi_education, 
                title = 'coi education' , 
                description = 'child opportunity index education domain'
                ) |>
  add_col_attrs(coi_health_env, 
                title = 'coi health env' , 
                description = 'child opportunity index health and environment domain'
                ) |>
  add_col_attrs(coi_social_econ, 
                title = 'coi social econ' , 
                description = 'child opportunity index social and economic domain'
                ) |>
  add_col_attrs(coi, 
                title = 'coi' , 
                description = 'child opportunity index'
                ) |>
  add_col_attrs(dep_index_fraction_assisted_income, 
                title = 'dep index fraction assisted income' , 
                description = 'fraction assisted income used for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index_fraction_high_school_edu, 
                title = 'dep index fraction high school edu' , 
                description = 'fraction high school education for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index_median_income, 
                title = 'dep index median income' , 
                description = 'median household income for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index_fraction_no_health_ins, 
                title = 'dep index fraction no health ins' , 
                description = 'fraction no health insurance for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index_fraction_poverty, 
                title = 'dep index fraction poverty' , 
                description = 'fraction poverty for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index_fraction_vacant_housing, 
                title = 'dep index fraction vacant housing' , 
                description = 'fraction vacant housing for deprivation index estimation'
                ) |>
  add_col_attrs(dep_index, 
                title = 'dep index' , 
                description = 'material deprivation index'
                ) |>
  add_col_attrs(lead_paint, 
                title = 'lead paint' , 
                description = 'lead paint indicator'
                ) |>
  add_col_attrs(diesel_pm, 
                title = 'diesel pm' , 
                description = 'diesel pm concentration'
                ) |>
  add_col_attrs(cancer_risk, 
                title = 'cancer risk' , 
                description = 'cancer risk'
                ) |>
  add_col_attrs(resp_hazard_ind, 
                title = 'resp hazard ind' , 
                description = 'respiratory hazard index'
                ) |>
  add_col_attrs(traffic_proximity, 
                title = 'traffic proximity' , 
                description = 'traffic proximity and volume'
                ) |>
  add_col_attrs(major_discharger_water, 
                title = 'major discharger water' , 
                description = 'major direct dischargers to water indicator'
                ) |>
  add_col_attrs(nat_priority_proximity, 
                title = 'nat priority proximity' , 
                description = 'proximity to npl sites'
                ) |>
  add_col_attrs(risk_management_proximity, 
                title = 'risk management proximity' , 
                description = 'proximity to rmp facilities'
                ) |>
  add_col_attrs(disposal_proximity, 
                title = 'disposal proximity' , 
                description = 'proximity to tsdf facilities'
                ) |>
  add_col_attrs(ozone_conc, 
                title = 'ozone conc' , 
                description = 'ozone cocentration'
                ) |>
  add_col_attrs(pm_conc, 
                title = 'pm conc' , 
                description = 'pm concentration'
                ) |>
  add_col_attrs(low_food_access_flag, 
                title = 'low food access flag' , 
                description = 'low food access flag'
                ) |>
  add_col_attrs(low_food_access_pop, 
                title = 'low food access pop' , 
                description = 'low food access pop'
                ) |>
  add_col_attrs(low_food_access_pct, 
                title = 'low food access pct' , 
                description = 'low food access percentage'
                ) |>
  add_col_attrs(food_insecurity_pct, 
                title = 'food insecurity pct' , 
                description = 'percent food insecurity'
                ) |>
  add_col_attrs(hpsa_mh, 
                title = 'hpsa mh' , 
                description = 'mental health professional shortage area'
                ) |>
  add_col_attrs(hpsa_pc, 
                title = 'hpsa pc' , 
                description = 'primary care professional shortage area'
                ) |>
  add_col_attrs(ice, 
                title = 'ice' , 
                description = 'racial economic index of concentration at the extremes'
                ) |>
  add_col_attrs(pct_crowding, 
                title = 'pct crowding' , 
                description = 'percent crowding'
                ) |>
  add_col_attrs(mrfei, 
                title = 'mrfei' , 
                description = 'modified retail food environment index'
                ) |>
  add_col_attrs(mua, 
                title = 'mua' , 
                description = 'medically underserved area'
                ) |>
  add_col_attrs(pct_1or2_risk_factors, 
                title = 'pct 1or2 risk factors' , 
                description = 'percent 1 or 2 community resilience risk factors'
                ) |>
  add_col_attrs(pct_3ormore_risk_factors, 
                title = 'pct 3ormore risk factors' , 
                description = 'percent 3 or more community resilience risk factors'
                ) |>
  add_col_attrs(sdi, 
                title = 'sdi' , 
                description = 'social deprivation index'
                ) |>
  add_col_attrs(svi_socioeconomic, 
                title = 'svi socioeconomic' , 
                description = 'social vulnerability index socioeconomic theme'
                ) |>
  add_col_attrs(svi_household_comp, 
                title = 'svi household comp' , 
                description = 'social vulnerability index household composition theme'
                ) |>
  add_col_attrs(svi_minority, 
                title = 'svi minority' , 
                description = 'social vulnerability index minority theme'
                ) |>
  add_col_attrs(svi_housing_transportation, 
                title = 'svi housing transportation' , 
                description = 'social vulnerability index housing and transportation theme'
                ) |>
  add_col_attrs(svi, 
                title = 'svi' , 
                description = 'social vulnerability index'
                ) |>
  add_col_attrs(walkability_index, 
                title = 'walkability index' , 
                description = 'walkability index'
                ) |>
  add_col_attrs(fraction_poverty_2019, 
                title = 'fraction poverty' , 
                description = 'fraction of population with income in past 12 months below poverty level'
                ) |>
  add_col_attrs(fraction_poverty_moe_2019, 
                title = 'fraction poverty moe' , 
                description = 'fraction of population with income in past 12 months below poverty level margin of error'
                ) |>
  add_col_attrs(n_children_lt18_2019, 
                title = 'n children lt18' , 
                description = 'number of children under 18'
                ) |>
  add_col_attrs(n_children_lt18_moe_2019, 
                title = 'n children lt18 moe' , 
                description = 'number of children under 18 margin of error'
                ) |>
  add_col_attrs(n_pop_2019, 
                title = 'n pop' , 
                description = 'total popoulation'
                ) |>
  add_col_attrs(n_pop_moe_2019, 
                title = 'n pop moe' , 
                description = 'total popoulation margin of error'
                ) |>
  add_col_attrs(n_household_lt18_2019, 
                title = 'n household lt18' , 
                description = 'number of households with children under 18'
                ) |>
  add_col_attrs(n_household_lt18_moe_2019, 
                title = 'n household lt18 moe' , 
                description = 'number of households with children under 18 margin of error'
                ) |>
  add_col_attrs(n_household_2019, 
                title = 'n household' , 
                description = 'number of households'
                ) |>
  add_col_attrs(n_household_moe_2019, 
                title = 'n household moe' , 
                description = 'number of households margin of error'
                ) |>
  add_col_attrs(fraction_insured_2019, 
                title = 'fraction insured' , 
                description = 'fraction of people insured'
                ) |>
  add_col_attrs(fraction_insured_moe_2019, 
                title = 'fraction insured moe' , 
                description = 'fraction of people insured margin of error'
                ) |>
  add_col_attrs(fraction_snap_2019, 
                title = 'fraction snap' , 
                description = 'fraction of households receiving snap'
                ) |>
  add_col_attrs(fraction_snap_moe_2019, 
                title = 'fraction snap moe' , 
                description = 'fraction of households receiving snap margin of error'
                ) |>
  add_col_attrs(fraction_fam_nospouse_2019, 
                title = 'fraction fam nospouse' , 
                description = 'fraction of family households with a single householder'
                ) |>
  add_col_attrs(fraction_fam_nospouse_moe_2019, 
                title = 'fraction fam nospouse moe' , 
                description = 'fraction of family households with a single householder margin of error'
                ) |>
  add_col_attrs(fraction_employment_2019, 
                title = 'fraction employment' , 
                description = 'fraction of people employed'
                ) |>
  add_col_attrs(fraction_employment_moe_2019, 
                title = 'fraction employment moe' , 
                description = 'fraction of people employed margin of error'
                ) |>
  add_col_attrs(n_housing_units_2019, 
                title = 'n housing units' , 
                description = 'number of housing units'
                ) |>
  add_col_attrs(n_housing_units_moe_2019, 
                title = 'n housing units moe' , 
                description = 'number of housing units margin of error'
                ) |>
  add_col_attrs(median_home_value_2019, 
                title = 'median home value' , 
                description = 'median value of owner-occupied housing units'
                ) |>
  add_col_attrs(median_home_value_moe_2019, 
                title = 'median home value moe' , 
                description = 'median value of owner-occupied housing units margin of error'
                ) |>
  add_col_attrs(median_home_value_2010adj_2019, 
                title = 'median home value 2010adj' , 
                description = 'median value of owner-occupied housing units (in 2010 usd)'
                ) |>
  add_col_attrs(fraction_housing_renters_2019, 
                title = 'fraction housing renters' , 
                description = 'fraction of housing units occupied by renters'
                ) |>
  add_col_attrs(fraction_housing_renters_moe_2019, 
                title = 'fraction housing renters moe' , 
                description = 'fraction of housing units occupied by renters margin of error'
                ) |>
  add_col_attrs(median_rent_to_income_percentage_2019, 
                title = 'median rent to income percentage' , 
                description = 'median rent to income percentage'
                ) |>
  add_col_attrs(median_rent_to_income_percentage_moe_2019, 
                title = 'median rent to income percentage moe' , 
                description = 'median rent to income percentage margin of error'
                ) |>
  add_col_attrs(fraction_high_rent_2019, 
                title = 'fraction high rent' , 
                description = 'fraction of housing units paying at least 30% of income on rent'
                ) |>
  add_col_attrs(fraction_high_rent_moe_2019, 
                title = 'fraction high rent moe' , 
                description = 'fraction of housing units paying at least 30% of income on rent margin of error'
                ) |>
  add_col_attrs(fraction_conditions_2019, 
                title = 'fraction conditions' , 
                description = 'fraction of housing units with substandard housing conditions'
                ) |>
  add_col_attrs(fraction_conditions_moe_2019, 
                title = 'fraction conditions moe' , 
                description = 'fraction of housing units with substandard housing conditions margin of error'
                ) |>
  add_col_attrs(fraction_builtbf1970_2019, 
                title = 'fraction builtbf1970' , 
                description = 'fraction of housing units built before 1970'
                ) |>
  add_col_attrs(fraction_builtbf1970_moe_2019, 
                title = 'fraction builtbf1970 moe' , 
                description = 'fraction of housing units built before 1970 margin of error'
                ) |>
  add_col_attrs(fraction_vacant_2019, 
                title = 'fraction vacant' , 
                description = 'fraction of housing units that are vacant'
                ) |>
  add_col_attrs(fraction_vacant_moe_2019, 
                title = 'fraction vacant moe' , 
                description = 'fraction of housing units that are vacant margin of error'
                ) |>
  add_col_attrs(fraction_nhl_2019, 
                title = 'fraction nhl' , 
                description = 'fraction of people not hispanic/latino'
                ) |>
  add_col_attrs(fraction_nhl_moe_2019, 
                title = 'fraction nhl moe' , 
                description = 'fraction of people not hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_nhl_w_2019, 
                title = 'fraction nhl w' , 
                description = 'fraction of people white and not hispanic/latino'
                ) |>
  add_col_attrs(fraction_nhl_w_moe_2019, 
                title = 'fraction nhl w moe' , 
                description = 'fraction of people white and not hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_nhl_b_2019, 
                title = 'fraction nhl b' , 
                description = 'fraction of people black and not hispanic/latino'
                ) |>
  add_col_attrs(fraction_nhl_b_moe_2019, 
                title = 'fraction nhl b moe' , 
                description = 'fraction of people black and not hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_nhl_o_2019, 
                title = 'fraction nhl o' , 
                description = 'fraction of people not black, not white, and not hispanic/latino'
                ) |>
  add_col_attrs(fraction_nhl_o_moe_2019, 
                title = 'fraction nhl o moe' , 
                description = 'fraction of people not black, not white, and not hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_hl_2019, 
                title = 'fraction hl' , 
                description = 'fraction of people hispanic/latino'
                ) |>
  add_col_attrs(fraction_hl_moe_2019, 
                title = 'fraction hl moe' , 
                description = 'fraction of people hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_hl_w_2019, 
                title = 'fraction hl w' , 
                description = 'fraction of people white and hispanic/latino'
                ) |>
  add_col_attrs(fraction_hl_w_moe_2019, 
                title = 'fraction hl w moe' , 
                description = 'fraction of people white and hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_hl_b_2019, 
                title = 'fraction hl b' , 
                description = 'fraction of people black and hispanic/latino'
                ) |>
  add_col_attrs(fraction_hl_b_moe_2019, 
                title = 'fraction hl b moe' , 
                description = 'fraction of people black and hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_hl_o_2019, 
                title = 'fraction hl o' , 
                description = 'fraction of people not black, not white, and hispanic/latino'
                ) |>
  add_col_attrs(fraction_hl_o_moe_2019, 
                title = 'fraction hl o moe' , 
                description = 'fraction of people not black, not white, and hispanic/latino margin of error'
                ) |>
  add_col_attrs(fraction_lesh_2019, 
                title = 'fraction lesh' , 
                description = 'fraction of households speaking limited english'
                ) |>
  add_col_attrs(fraction_lesh_moe_2019, 
                title = 'fraction lesh moe' , 
                description = 'fraction of households speaking limited english margin of error'
                ) |>
  add_col_attrs(median_income_2019, 
                title = 'median income' , 
                description = 'median household income'
                ) |>
  add_col_attrs(median_income_moe_2019, 
                title = 'median income moe' , 
                description = 'median household income margin of error'
                ) |>
  add_col_attrs(median_income_2010adj_2019, 
                title = 'median income 2010adj' , 
                description = 'median household income (in 2010 usd)'
                ) |>
  add_col_attrs(fraction_hs_2019, 
                title = 'fraction hs' , 
                description = 'fraction of adults with at least high school education'
                ) |>
  add_col_attrs(fraction_hs_moe_2019, 
                title = 'fraction hs moe' , 
                description = 'fraction of adults with at least high school education margin of error'
                ) |>
  add_col_attrs(ags_Total, 
                title = 'total crime risk' , 
                description = 'total crime risk'
                ) |>
  add_col_attrs(ags_Personal, 
                title = 'personal crime risk' , 
                description = 'personal crime risk'
                ) |>
  add_col_attrs(ags_Murder, 
                title = 'murder crime risk' , 
                description = 'murder crime risk'
                ) |>
  add_col_attrs(ags_Rape, 
                title = 'rape crime risk' , 
                description = 'rape crime risk'
                ) |>
  add_col_attrs(ags_Robbery, 
                title = 'robbery crime risk' , 
                description = 'robbery crime risk'
                ) |>
  add_col_attrs(ags_Assault, 
                title = 'assault crime risk' , 
                description = 'assault crime risk'
                ) |>
  add_col_attrs(ags_Property, 
                title = 'property crime risk' , 
                description = 'property crime risk'
                ) |>
  add_col_attrs(ags_Burglary, 
                title = 'burglary crime risk' , 
                description = 'burglary crime risk'
                ) |>
  add_col_attrs(ags_Theft, 
                title = 'theft crime risk' , 
                description = 'theft crime risk'
                ) |>
  add_col_attrs(ags_MotVeh, 
                title = 'motor vehicle crime risk' , 
                description = 'motor vehicle crime risk')
  
# save
saveRDS(d, "data/census_tract_lvl_data.rds")

