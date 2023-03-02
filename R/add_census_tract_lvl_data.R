
library(tidyverse)

d <- readRDS("data/census_tract_identifier.rds")

#---------------------------------------------------------
# tract_indices (2010 census tract id)
#---------------------------------------------------------
tract_indices <- readr::read_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0/tract_indices.csv")

d <- d |> 
  left_join(tract_indices, by=c("census_tract_id_2010" = "census_tract_id")) |> 
  rename(dep_index_2018 = dep_index)
dim(d)

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
dim(d)

#-------------------------------------------------------------
# 2019 dep index
# Note the 2019 dep index was calculated using 2012-2020 data
#-------------------------------------------------------------
di <- readRDS("U:/Investigator Folders/DBE/Cole Brokamp/GRAPPH/harmonized_historical_ACS_data/harmonized_historical_ACS_data/data/dep_index_2012-2020.rds") |> 
  filter(year == 2019) |> 
  select(dep_index_2019 = dep_index,
         census_tract_id_2010)

d <- d |> 
  left_join(di, by = "census_tract_id_2010")
dim(d)

#---------------------------------------------------------
# AGS crime risk
# Hamilton county tracts only
# 2010 census tract vintage
#---------------------------------------------------------
ags_crime <- read_csv("raw-data/AGS_crime_risk/ags_crime_risk.csv") |> 
  rename_all(~ paste0("ags_", .x)) |> 
  rename(census_tract_id = ags_census_tract_id) |> 
  mutate(census_tract_id = as.character(census_tract_id))

d <- d |> 
  left_join(ags_crime, by=c("census_tract_id_2010"="census_tract_id"))
dim(d)

# save
saveRDS(d, "data/census_tract_lvl_data.rds")

