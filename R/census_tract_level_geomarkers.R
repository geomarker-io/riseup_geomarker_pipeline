library(dplyr, warn.conflicts = FALSE)
library(codec)
library(cincy)

# use 2010 vintage tract identifiers to join 2019 data from hh_acs_measures and add neighborhood
d <-
  readRDS("data/geocodes.rds") |>
  select(PAT_ENC_CSN_ID, HOSP_ADMSN_TIME, PAT_MRN_ID,
         census_tract_id = census_tract_id_2010) |>
  cincy::add_neighborhood(vintage = "2010")

# 2019 hh_acs_measures
hh_acs_2019 <-
  read_tdr_csv("https://github.com/geomarker-io/hh_acs_measures/releases/download/v1.0.0") |>
  filter(year == 2019) |>
  select(-year, -census_tract_vintage)

d <- left_join(d, hh_acs_2019, by = "census_tract_id")

# AGS crime risk
ags_crime_risk <- read_tdr_csv("https://github.com/geomarker-io/hamilton_crime_risk/releases/download/v0.1.0")
d <- d |> left_join(ags_crime_risk, by = "census_tract_id")

# drop name columns that will already be included in data/geocodes.rds
d <- select(d, -census_tract_id)

# save
saveRDS(d, "data/census_tract_level_data.rds")
