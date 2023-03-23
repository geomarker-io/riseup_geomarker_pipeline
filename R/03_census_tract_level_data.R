library(dplyr)
library(CODECtools)
library(cincy)

d <- readRDS("data/geocodes.rds")

# add_neighborhood
# (doesn't work with more than one census tract id column)
d |>
  rename(foo = census_tract_id_2020) |>
  cincy::add_neighborhood(vintage = "2010") |>
  rename(census_tract_id_2020 = foo)

# 2019 hh_acs_measures
hh_acs_2019 <-
  read_tdr_csv("https://github.com/geomarker-io/hh_acs_measures/releases/download/v1.0.0") |>
  filter(year == 2019)
d <-
  left_join(d,
          select(hh_acs_2019, -year, -census_tract_vintage),
          by = c("census_tract_id_2010" = "census_tract_id"))

# AGS crime risk
ags_crime_risk <- read_tdr_csv("https://github.com/geomarker-io/hamilton_crime_risk/releases/download/v0.1.0")
d <- d |> left_join(ags_crime_risk, by = c("census_tract_id_2010" = "census_tract_id"))

# save
saveRDS(d, "data/census_tract_level_data.rds")

