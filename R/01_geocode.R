library(dplyr)
library(dht)

d <- readRDS("data/cleaned_addresses.rds")

# temporary smaller dataset
set.seed(11)
d <- sample_n(d, 2000)

# geocode
d <- d |> 
  rename(address = parsed_address) |>
  dht::degauss_run("geocoder", "3.3.0", quiet = FALSE) |>
  rename(parsed_address = address) |>
  select(-starts_with("matched_")) |>
  select(-score, -precision)

# 2010 census block group and tract
d <- d |> degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE)

# 2020 census block group and tract
d <- d |> degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)

saveRDS(d, "data/geocodes.rds")
