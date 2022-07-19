library(tidyverse)
library(lubridate)

d <- read_csv("./data/Admission2022_geocoder_3.2.0_score_threshold_0.5_dep_index_0.2.0_roads_0.2.1_400m_buffer_aadt_0.2.0_400m_buffer_greenspace_0.3.0_drivetime_1.1.0_cchmc.csv")

unique(d$mapped_race)

d_adm <- d %>%
  filter(asthma_encounter == 1) %>%
  select(pat_id:pat_enc_csn_id, hosp_admsn_time, fips_tract_id, mapped_race) %>%
  mutate(date = as.Date(hosp_admsn_time),
         year = year(date),
         month = month(date),
         race = ifelse(mapped_race == "Black or African American", "Black or African American", "Other")) %>%
  group_by(year, month, fips_tract_id, race) %>%
  tally() %>%
  mutate(date = as.Date(glue::glue("{year}-{month}-01"))) %>%
  rename(num_admissions = n)

write_csv(d_adm, "./data/admissions_by_month_race_tract.csv")
saveRDS(d_adm, "./data/admissions_by_month_race_tract.rds")
