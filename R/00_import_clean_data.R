library(tidyverse)
library(lubridate)
library(dht)

# read in raw admission data
d <- readr::read_csv("data-raw/Hospital Admissions.csv", 
                     na = c("NA", "-", "NULL")) # n = 135871 records
dim(d)

# remove a duplicated record (based on PAT_ENC_CSN_ID) from current dataset
d <- d |> 
  filter(!(PAT_ENC_CSN_ID == "549864470" & MAPPED_RACE == "Unknown")) # 135870
dim(d)

# limit data to patients admitted between 1/1/2016 and 12/31/2021
d <- d |> 
  filter(HOSP_ADMSN_TIME <= ymd(20211231)) # 124244
dim(d)

d.address <- d |>  
  separate(PAT_ZIP, 
           c("PAT_ZIP1","PAT_ZIP2"), 
           sep = "-") |> 
  unite("address", 
        c(PAT_ADDR_1, PAT_CITY, PAT_STATE, PAT_ZIP1), 
        remove = FALSE, 
        sep=" ") |> 
  select(PAT_ENC_CSN_ID, address)

# postal
d <- d |> 
  degauss_run("postal", "0.1.4", quiet = FALSE) 
