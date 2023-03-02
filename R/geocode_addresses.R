
.cran_packages <- c("dht", "CODECtools")
.inst <- .cran_packages %in% installed.packages()
if(any(!.inst)) {
  install.packages(.cran_packages[!.inst], repos = "http://cran.us.r-project.org")
}

library(tidyverse)
library(dht)
library(CODECtools)

d <- readRDS("data/addresses.rds")

# postal
d <- d |> 
  degauss_run("postal", "0.1.4", quiet = FALSE) 

# geocoder
d <- d |> 
  degauss_run("geocoder", "3.3.0", quiet = FALSE) |>  # duplicated records
  distinct(.keep_all = TRUE)   # keep distinct rows

saveRDS(d, "data/addresses_geocoded.rds")


              