library(dplyr)
library(dht)
library(codec)

d <- readRDS("data/geocodes.rds")

# roads
d <- d |>
  degauss_run("roads", "0.2.1", quiet = FALSE)

# aadt
d <- d |>
  degauss_run("aadt", "0.2.0", quiet = FALSE) |>
  select(-.row)

# greenspace
d <- d |>
  degauss_run("greenspace", "0.3.0", quiet = FALSE)

# drivetime
d <- d |>
  degauss_run("drivetime", "1.2.0", argument = "cchmc", quiet = FALSE)

# add column attributes
d <- d |>
  add_col_attrs(dist_to_1100,
    title = "Distance to Nearest Primary Road",
    description = "distance (meters) to the nearest S1100 road"
  ) |>
  add_col_attrs(dist_to_1200,
    title = "Distance to Nearest Secondary Road",
    description = "distance (meters) to the nearest S1200 road"
  ) |>
  add_col_attrs(length_1100,
    title = "Length of Primary Roads",
    description = "length (meters) of S1100 roads within a 400 m buffer"
  ) |>
  add_col_attrs(length_1200,
    title = "Length of Secondary Roads",
    description = "length (meters) of S1200 roads within a 400 m buffer"
  ) |>
  add_col_attrs(length_stop_go,
    title = "Length of Roads with Stop and Go Traffic",
    description = "total length of arterial roads (meters) within 400 m"
  ) |>
  add_col_attrs(length_moving,
    title = "Length of Roads with Moving Traffic",
    description = "total length of interstates, expressways, and freeways (meters) within 400 m"
  ) |>
  add_col_attrs(vehicle_meters_stop_go,
    title = "Stop and Go Traffic (vehicle-m)",
    description = "average daily number of vehicles multiplied by the length of arterial roads (vehicle-meters)"
  ) |>
  add_col_attrs(vehicle_meters_moving,
    title = "Moving Traffic (vehicle-m)",
    description = "average daily number of vehicles multiplied by the length of interstates, expressways, and freeways (vehicle-meters)"
  ) |>
  add_col_attrs(truck_meters_stop_go,
    title = "Stop and Go Truck Traffic (truck-m)",
    description = "average daily number of trucks multiplied by the length of arterial roads (truck-meters)"
  ) |>
  add_col_attrs(truck_meters_moving,
    title = "Moving Truck Traffic (truck-m)",
    description = "average daily number of trucks multiplied by the length of interstates, expressways, and freeways (truck-meters)"
  ) |>
  add_col_attrs(evi_500,
    title = "EVI (500m buffer)",
    description = "average enhanced vegetation index within a 500 meter buffer radius"
  ) |>
  add_col_attrs(evi_1500,
    title = "EVI (1500m buffer)",
    description = "average enhanced vegetation index within a 1500 meter buffer radius"
  ) |>
  add_col_attrs(evi_2500,
    title = "EVI (2500m buffer)",
    description = "average enhanced vegetation index within a 2500 meter buffer radius"
  ) |>
  add_col_attrs(drive_time,
    title = "Drive Time to CCHMC",
    description = 'drive time in minutes (in 6 minute intervals, ">60" if more than 1 hour drive time)'
  ) |>
  add_col_attrs(distance,
    title = "Distance to CCHMC",
    description = "distance in meters"
  ) |>
  add_type_attrs()

saveRDS(d, "data/exact_location_geomarkers.rds")
