#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

input <- args[1]
output <- args[2]

library(tidyverse)

addrfile <- read_csv(paste0("raw-data/", input, ".csv"))

addrfile <- addrfile %>%
  mutate(pat_zip_clean = str_split(pat_zip, "-", simplify = TRUE)[, 1]) %>%
  unite("address", c(pat_addr_1, pat_city, pat_state, pat_zip_clean), remove = FALSE, sep = " ")

outfile <- paste0("data/", output, ".csv")
write_csv(addrfile, outfile)
