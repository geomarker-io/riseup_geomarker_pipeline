
library(tidyverse)
library(dht)

d <- readRDS("data/addresses_geocoded.rds")

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
  degauss_run("drivetime", "1.2.0", argument = "cchmc", quiet = FALSE)

saveRDS(d, "data/degauss_geomarker_library.rds")
