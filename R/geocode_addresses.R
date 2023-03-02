
library(tidyverse)
library(dht)

d <- readRDS("data/addresses.rds")

# postal
d <- d |> 
  degauss_run("postal", "0.1.4", quiet = FALSE) 

# geocoder
d <- d |> 
  degauss_run("geocoder", "3.3.0", quiet = FALSE) |>  # duplicated records
  distinct(.keep_all = TRUE)   # keep distinct rows

saveRDS(d, "data/addresses_geocoded.rds")
