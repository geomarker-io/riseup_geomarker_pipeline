library(dplyr, warn.conflicts = FALSE)
library(dht)
library(fr)

rd <- readRDS("data/geocodes.rds")

d_in <-
  tibble::as_tibble(rd) |>
  select(PAT_ENC_CSN_ID, HOSP_ADMSN_TIME, PAT_MRN_ID, lat, lon)

d <- na.omit(d_in)

d <- d |> degauss_run("aadt", "0.2.2", quiet = FALSE)
d <- d |> degauss_run("greenspace", "0.3.0", quiet = FALSE)
d <- d |> degauss_run("drivetime", "1.2.0", argument = "cchmc", quiet = FALSE)

out <-
  left_join(select(d_in, -lat, -lon),
            select(d, -lat, -lon),
            by = c("PAT_ENC_CSN_ID", "HOSP_ADMSN_TIME", "PAT_MRN_ID")) |>
  as_fr_tdr(.template = rd) |>
  update_field("length_stop_go",
    title = "Length of Roads with Stop and Go Traffic",
    description = "total length of arterial roads (meters) within 400 m"
  ) |>
  update_field("length_moving",
    title = "Length of Roads with Moving Traffic",
    description = "total length of interstates, expressways, and freeways (meters) within 400 m"
  ) |>
  update_field("vehicle_meters_stop_go",
    title = "Stop and Go Traffic (vehicle-m)",
    description = "average daily number of vehicles multiplied by the length of arterial roads (vehicle-meters)"
  ) |>
  update_field("vehicle_meters_moving",
    title = "Moving Traffic (vehicle-m)",
    description = "average daily number of vehicles multiplied by the length of interstates, expressways, and freeways (vehicle-meters)"
  ) |>
  update_field("truck_meters_stop_go",
    title = "Stop and Go Truck Traffic (truck-m)",
    description = "average daily number of trucks multiplied by the length of arterial roads (truck-meters)"
  ) |>
  update_field("truck_meters_moving",
    title = "Moving Truck Traffic (truck-m)",
    description = "average daily number of trucks multiplied by the length of interstates, expressways, and freeways (truck-meters)"
  ) |>
  update_field("evi_500",
    title = "EVI (500m buffer)",
    description = "average enhanced vegetation index within a 500 meter buffer radius"
  ) |>
  update_field("evi_1500",
    title = "EVI (1500m buffer)",
    description = "average enhanced vegetation index within a 1500 meter buffer radius"
  ) |>
  update_field("evi_2500",
    title = "EVI (2500m buffer)",
    description = "average enhanced vegetation index within a 2500 meter buffer radius"
  ) |>
  update_field("drive_time",
    title = "Drive Time to CCHMC",
    description = 'drive time in minutes (in 6 minute intervals, ">60" if more than 1 hour drive time)'
  ) |>
  update_field("distance",
    title = "Distance to CCHMC",
    description = "distance in meters"
  )

out@name <- "exact_location_geomarkers"

saveRDS(out, "data/exact_location_geomarkers.rds")
