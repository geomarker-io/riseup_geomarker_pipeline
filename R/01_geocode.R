library(dplyr)

d <- readRDS("data/cleaned_addresses.rds")

# geocoder
d <- d |> 
  rename(address = parsed_address) |>
  dht::degauss_run("geocoder", "3.3.0", argument = "all", quiet = FALSE)

# 2010 census block group and tract
d <- d |>
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)

# 2020 census block group and tract
d <- d |>
  degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)

