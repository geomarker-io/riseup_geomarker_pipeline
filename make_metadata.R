library(tidyverse)
library(CODECtools)

d <- readRDS("raw-data/hospital_admission_joined_parcel_nonparcel_temporal.rds")

cat("#### Metadata and Schema\n\n", file = "metadata.md", append = FALSE)
d |>
  select(cleaned_address:n_shots_total) |>
  CODECtools::glimpse_tdr() |>
  knitr::kable() |>
  cat(file = "metadata.md", sep = "\n", append = TRUE)

