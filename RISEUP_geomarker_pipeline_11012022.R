
remotes::install_github("degauss-org/dht")
library(tidyverse)
library(lubridate)
library(dht)

input = "Admissions_for_Jan_2022_asthma_pul_and_gen_peds.csv"
output = "data/Admissions_for_Jan_2022_asthma_pul_and_gen_peds_addedVars.csv"

# organize addresses
data.in <- read_csv(paste0("raw-data/", input)) |>  
  mutate(pat_zip_clean = str_split(pat_zip, "-", simplify=TRUE)[,1]) |>  
  unite("address", c(pat_addr_1, pat_city, pat_state, pat_zip_clean), remove = FALSE, sep=" ")

# postal
d <- data.in |> 
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

# nlcd
d <- d |> 
  degauss_run("nlcd", "0.2.1", quiet = FALSE) |> 
  filter(year == 2016 | is.na(year)) |> 
  select(-year)

# census tract id for merging purpose
d <- d |>
  mutate(year_orig = year(hosp_admsn_time)) |>  
  mutate(year = replace(year_orig,            # for identifying ACS data year
                        year_orig > 2020, 
                        2020)) |>
  mutate(census_tract_id_acs = ifelse(year < 2020,   
                                  census_tract_id_2010,
                                  census_tract_id_2020),
         census_tract_vintage = ifelse(year < 2020,
                                       2010,
                                       2020)) |> 
  select(-year_orig)

# tract_indices (2010 census tract id)
tract_indices <- readr::read_csv("https://github.com/geomarker-io/tract_indices/releases/download/v0.3.0/tract_indices.csv")

d <- d |> 
  left_join(tract_indices, by=c("census_tract_id_2010" = "census_tract_id"))

# historical acs data (2010 or 2020 census tract id)
hh_acs <- readr::read_csv("https://codec-data.s3.amazonaws.com/hh_acs_measures/hh_acs_measures.csv")

d <- d |> 
  left_join(hh_acs, by=c("census_tract_id_acs"="census_tract_id", "year"))

saveRDS(d, "data/data_merged_11012022.rds")

write_csv(d, file = output)







