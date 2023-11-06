library(dplyr, warn.conflicts = FALSE)
library(codec)
library(cincy)
library(s2)

s2_tracts <- function(state, year = 2019) {
  tigris::tracts(state = state, year = year, progress_bar = FALSE, keep_zipped_shapefile = TRUE) |>
    mutate(s2_geography = as_s2_geography(geometry)) |>
    tibble::as_tibble() |>
    select(-geometry)
}

d_in <-
  readRDS("data/geocodes.rds") |>
  select(PAT_ENC_CSN_ID, HOSP_ADMSN_TIME, PAT_MRN_ID, lat, lon) |>
  mutate(s2_geography = s2_geog_point(lon, lat))

states <-
  tigris::states(year = 2019) |>
  select(GEOID) |>
  mutate(s2_geography = as_s2_geography(geometry)) |>
  tibble::as_tibble() |>
  select(-geometry)

d_in$state <- states[s2_closest_feature(d_in$s2_geography, states$s2_geography), "GEOID", drop = TRUE]

message("found ", scales::number(length(unique(na.omit(d_in$s2_geography))), big.mark = ","), " unique locations across ", length(unique(na.omit(d_in$state))), " states")

if (any(is.na(d_in$state))) {
  message(scales::number(sum(is.na(d_in$state)), big.mark = ","),
          " points had missing geocodes or were outside the United States")
}

d <- 
  na.omit(d_in) |>
  nest_by(state) |>
  ungroup() |>
  mutate(state_tracts = purrr::map(state, s2_tracts, .progress = "(down)loading census tracts for each state")) |>
  mutate(census_tract_id =
           purrr::map2(
             data, state_tracts,
             \(d, st) st[s2_closest_feature(d$s2_geography,
                                            st$s2_geography), "GEOID", drop = TRUE],
             .progress = "intersecting census tracts for each state"
           )) |>
  select(data, census_tract_id) |>
  tidyr::unnest(cols = c(data, census_tract_id)) |>
  add_col_attrs(census_tract_id,
                description = "2019 TIGER/Line census tract identifier for the 2010 decennial census") |>
  select(-s2_geography, -lat, -lon)

d_out <- left_join(d_in, d, by = c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID"))

d_out <- cincy::add_neighborhood(d_out, vintage = "2010")

# 2019 hh_acs_measures
hh_acs_2019 <-
  read_tdr_csv("https://github.com/geomarker-io/hh_acs_measures/releases/download/v1.1.0") |>
  filter(year == 2019) |>
  select(-year, -census_tract_vintage)

d_out <- left_join(d_out, hh_acs_2019, by = "census_tract_id")

# tract_indices
tract_indices <-
  read_tdr_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0")

d_out <- left_join(d_out, tract_indices, by = "census_tract_id")

# AGS crime risk
ags_crime_risk <- read_tdr_csv("https://github.com/geomarker-io/hamilton_crime_risk/releases/download/v0.1.0")
names(ags_crime_risk) <- paste0("crime_", tolower(names(ags_crime_risk)))
d_out <- left_join(d_out, ags_crime_risk, by = c("census_tract_id" = "crime_census_tract_id"))

# save
d_out |>
  select(-lat, -lon, -s2_geography, -state) |>
  saveRDS("data/census_tract_level_data.rds")
