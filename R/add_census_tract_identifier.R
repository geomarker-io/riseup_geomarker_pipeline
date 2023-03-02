
library(tidyverse)
library(dht)

d <- readRDS("data/addresses_geocoded.rds")

# 2010 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)

# 2020 Census Tract Geographies
d <- d |> 
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)

d <- d |> 
  select(PAT_ENC_CSN_ID, 
         census_block_group_id_2010, census_tract_id_2010, 
         census_block_group_id_2020, census_tract_id_2020)

saveRDS(d, "data/census_tract_identifier.rds")

