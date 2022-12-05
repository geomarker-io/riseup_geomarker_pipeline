
#remotes::install_github("degauss-org/dht")
library(tidyverse)
library(lubridate)
library(dht)
library(data.table)
#devtools::install_github("geomarker-io/CODECtools")
library(CODECtools)

#input = "Admissions_for_Jan_2022_asthma_pul_and_gen_peds.csv"
input = "Hospital Admissions.csv"

source("add_parcel_id.R")

#---------------------------------------------------------
# organize addresses
#---------------------------------------------------------

data.in <- readr::read_csv(paste0("raw-data/", input), na = c("NA", "-", "NULL")) |>  # n = 135871 records 
  mutate(pat_zip_clean = str_split(PAT_ZIP, "-", simplify=TRUE)[,1]) |>  
  unite("address", c(PAT_ADDR_1, PAT_CITY, PAT_STATE, pat_zip_clean), remove = FALSE, sep=" ") 

# cache the following functions locally to disk
fc <- memoise::cache_filesystem(fs::path(fs::path_wd(), "localcache"))
add_parcel_id <- memoise::memoise(add_parcel_id, omit_args = c("quiet"), cache = fc)
degauss_run <- memoise::memoise(degauss_run, omit_args = c("quiet"), cache = fc)

# Downloaded Hamilton parcels directly from release
# readr::read_csv("https://github.com/geomarker-io/hamilton_parcels/releases/download/v1.1.0/hamilton_parcels.csv")
# reported error

hamilton_parcels <- read_csv("data/hamilton_parcels.csv")

d <- add_parcel_id(data.in) |>
  tidyr::unnest(parcel_id, keep_empty = TRUE) |>
  dplyr::left_join(hamilton_parcels) 

dim(d)

#---------------------------------------------------------
# geocoding
#---------------------------------------------------------
start_time <- Sys.time()

# postal
d <- d |> 
  degauss_run("postal", "0.1.3", quiet = FALSE) 

# geocoder
d <- d |> 
  degauss_run("geocoder", "3.2.1", quiet = FALSE) 

# 2010 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)

# 2020 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)

# dep-index: merging from tract indices
# d <- d |> 
#  degauss_run("dep_index", "0.2.1", quiet = FALSE) 

# roads
d <- d |> 
  degauss_run("roads", "0.2.1", quiet = FALSE)

# aadt
d <- d |> 
  degauss_run("aadt", "0.2.0", quiet = FALSE) |> 
  select(-.row)

# greenspace
d <- d |> 
  degauss_run("greenspace", "0.3.0", quiet = FALSE)

# drivetime
d <- d |> 
  degauss_run("drivetime", "1.1.0", argument = "cchmc", quiet = FALSE)

end_time <- Sys.time()

end_time - start_time # Time difference of 7.365218 hours

# nlcd
d <- d |> 
  degauss_run("nlcd", "0.2.1", quiet = FALSE) |> 
  filter(year == 2016 | is.na(year)) |> 
  select(-year)

# census tract id for merging purpose
d <- d |>
  mutate(year_orig = year(HOSP_ADMSN_TIME)) |>  
  mutate(year = replace(year_orig,            # for identifying ACS data year
                        year_orig > 2020, 
                        2020)) |>
  mutate(census_tract_id_acs = ifelse(year < 2020,   
                                  census_tract_id_2010,
                                  census_tract_id_2020)) |> 
  select(-year_orig)


saveRDS(d, "data/HospitalAdmissions_degauss.rds")

#---------------------------------------------------------
# tract_indices (2010 census tract id)
#---------------------------------------------------------
tract_indices <- readr::read_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0/tract_indices.csv")

d <- d |> 
  left_join(tract_indices, by=c("census_tract_id_2010" = "census_tract_id"))

saveRDS(d, "data/HospitalAdmissions_degauss_ti.rds")

#---------------------------------------------------------
# historical acs data (2010 or 2020 census tract id)
#---------------------------------------------------------
hh_acs <- readr::read_csv("https://codec-data.s3.amazonaws.com/hh_acs_measures/hh_acs_measures.csv")

d <- d |> 
  left_join(hh_acs, by=c("census_tract_id_acs"="census_tract_id", "year")) |> 
  select(-census_tract_id_acs) # clean up

# save
saveRDS(d, "data/Hospital Admissions_merged_degauss_ti_acs.rds")









