
library(tidyverse)

d <-
  c("hospital_admission","degauss_geomarker_library", "nlcd", "census_tract_lvl_data") %>%
  map(~ readRDS(paste0("data/", ., ".rds"))) %>%
  reduce(dplyr::left_join, by = "PAT_ENC_CSN_ID")

saveRDS(d, "data/hospital_admission_joined_data.rds")


