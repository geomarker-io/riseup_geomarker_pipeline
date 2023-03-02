
library(tidyverse)

# read in raw admission data
d <- readRDS("data/hospital_admission.rds")

d.address <- d |>  
  separate(PAT_ZIP, 
           c("PAT_ZIP1","PAT_ZIP2"), 
           sep = "-") |> 
  unite("address", 
        c(PAT_ADDR_1, PAT_CITY, PAT_STATE, PAT_ZIP1), 
        remove = FALSE, 
        sep=" ") |> 
  select(PAT_ENC_CSN_ID, address)

saveRDS(d.address, "data/addresses.rds")