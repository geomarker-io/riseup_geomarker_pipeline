
.cran_packages <- c("tidycensus", "lubridate")
.inst <- .cran_packages %in% installed.packages()
if(any(!.inst)) {
  install.packages(.cran_packages[!.inst], repos = "http://cran.us.r-project.org")
}

library(tidyverse)
library(lubridate)

# read in raw admission data
d <- readr::read_csv("raw-data/Hospital Admissions.csv", 
                     na = c("NA", "-", "NULL")) # n = 135871 records
dim(d)

# data cleaning
# remove a duplicated record (based on PAT_ENC_CSN_ID) from current dataset
d <- d |> 
  filter(!(PAT_ENC_CSN_ID == "549864470" & MAPPED_RACE == "Unknown")) # 135870
dim(d)

# limit data to patients admitted between 1/1/2016 and 12/31/2021
d <- d |> 
  filter(HOSP_ADMSN_TIME <= ymd(20211231)) # 124244
dim(d)

saveRDS(d, "data/hospital_admission.rds")
