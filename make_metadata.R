library(tidyverse)
library(CODECtools)

d <- readRDS("data/riseup_geomarker_pipeline_output.rds")

cat("#### Metadata and Schema\n\n", file = "metadata.md", append = FALSE)
d |>
  select(parsed_address:n_shots_total) |>
  CODECtools::glimpse_tdr() |>
  knitr::kable() |>
  cat(file = "metadata.md", sep = "\n", append = TRUE)

