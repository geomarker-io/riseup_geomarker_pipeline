## library(tidyverse)
library(dplyr)
library(readr)
## library(lubridate)
## library(dht)

# read in raw admission data
d <- read_csv("data-raw/Hospital Admissions.csv",
              na = c("NA", "-", "NULL"),
              col_types = cols_only(PAT_MRN_ID = col_character(),
                                    PAT_ENC_CSN_ID = col_character(),
                                    HOSP_ADMSN_TIME = col_date(),
                                    PAT_ADDR_1 = col_character(),
                                    PAT_ADDR_2 = col_character(),
                                    PAT_CITY = col_character(),
                                    PAT_STATE = col_character(),
                                    PAT_ZIP = col_character()))

# remove a duplicated record (based on PAT_ENC_CSN_ID) from current dataset
d <- d |> filter(!(PAT_ENC_CSN_ID == "549864470" & MAPPED_RACE == "Unknown"))

# limit data to patients admitted between 1/1/2016 and 12/31/2021
d <- d |> filter(HOSP_ADMSN_TIME <= ymd(20211231))

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
