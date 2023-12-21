library(dplyr, warn.conflicts = FALSE)
library(fr)

rd <- readRDS("data/geocodes.rds")

d_in <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, ADMIT_DATE, MRN, lat, lon)

d <- na.omit(d_in)

readr::write_csv(d, "data/coordinates_for_drivetime.csv")
system2(
  "docker",
  c(
    "run", "--rm",
    "-v ${PWD}/data:/tmp",
    ifelse(Sys.info()["machine"] == "arm64", # use alt tag for m1/m2 macs
      "ghcr.io/degauss-org/drivetime:1.2.0-v8",
      "ghcr.io/degauss-org/drivetime:1.2.0"
    ),
    "coordinates_for_drivetime.csv",
    "cchmc"
  )
)

d <-
  readr::read_csv("data/coordinates_for_drivetime_drivetime_1.3.0_cchmc.csv", col_types = readr::cols(
    # TODO I messed up the tags for the v8 version; why does it name version 1.3 when using tag 1.2 of the docker image?
    PAT_ENC_CSN_ID = readr::col_character(),
    ADMIT_DATE = readr::col_date(format = "%Y-%m-%d"),
    MRN = readr::col_character(),
    drive_time = readr::col_factor(),
    distance = readr::col_double(),
    lat = readr::col_double(),
    lon = readr::col_double()
  ))

out <-
  left_join(select(d_in, -lat, -lon),
            select(d, -lat, -lon),
            by = c("PAT_ENC_CSN_ID", "ADMIT_DATE", "MRN")) |>
  as_fr_tdr(.template = rd) |>
  update_field("drive_time",
    title = "Drive Time to CCHMC",
    description = 'drive time in minutes (in 6 minute intervals, ">60" if more than 1 hour drive time)'
  ) |>
  update_field("distance",
    title = "Distance to CCHMC",
    description = "distance in meters"
  )

out@name <- "drivetime"

saveRDS(out, "data/drivetime.rds")
