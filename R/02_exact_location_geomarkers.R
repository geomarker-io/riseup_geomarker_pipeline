library(dplyr)
library(dht)
library(CODECtools)

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
  add_col_attrs(parsed_address,
                title = 'parsed address',
                description = 'parsed address'
                ) |>
  add_col_attrs(lat,
                title = 'lat',
                description = 'geocoded latitude coordinate'
                ) |>
  add_col_attrs(lon,
                title = 'lon',
                description = 'geocoded longitude coordinate'
                ) |>
  add_col_attrs(geocode_result,
                title = 'geocode result',
                description = 'character string summarizing the geocoding result (geocoded: the address was geocoded with a precision of either range or street and a score of 0.5 or greater; imprecise_geocode: the address was geocoded, but results were suppressed because the precision was intersection, zip, or city and/or the score was less than 0.5; po_box: the address was not geocoded because it is a PO Box; cincy_inst_foster_addr: the address was not geocoded because it is a known institutional address, not a residential address; non_address_text: the address was not geocoded because it was blank or listed as “foreign”, “verify”, or “unknown”)'
                ) |>
  add_col_attrs(census_block_group_id_2010,
                title = '2010 Census Block Group ID'
                ) |>
  add_col_attrs(census_tract_id_2010,
                title = '2010 Census Tract ID'
  ) |>
  add_col_attrs(census_block_group_id_2020,
                title = '2020 Census Block Group ID'
  ) |>
  add_col_attrs(census_tract_id_2020,
                title = '2020 Census Tract ID'
  ) |>
  add_col_attrs(dist_to_1100,
                title = 'dist to 1100',
                description = 'distance (meters) to the nearest S1100 road'
                ) |>
  add_col_attrs(dist_to_1200,
                title = 'dist to 1200',
                description = 'distance (meters) to the nearest S1200 road'
                ) |>
  add_col_attrs(length_1100,
                title = 'length 1100',
                description = 'length (meters) of S1100 roads within a 400 m buffer'
                ) |>
  add_col_attrs(length_1200,
                title = 'length 1200',
                description = 'length (meters) of S1200 roads within a 400 m buffer'
                ) |>
  add_col_attrs(length_stop_go,
                title = 'length stop go',
                description = 'total length of arterial roads (meters)'
                ) |>
  add_col_attrs(length_moving,
                title = 'length moving',
                description = 'total length of interstates, expressways, and freeways (meters)'
                ) |>
  add_col_attrs(vehicle_meters_stop_go,
                title = 'vehicle meters stop go',
                description = 'average daily number of vehicles multiplied by the length of arterial roads (vehicle-meters)'
                ) |>
  add_col_attrs(vehicle_meters_moving,
                title = 'vehicle meters moving',
                description = 'average daily number of vehicles multiplied by the length of interstates, expressways, and freeways (vehicle-meters)'
                ) |>
  add_col_attrs(truck_meters_stop_go,
                title = 'truck meters stop go',
                description = 'average daily number of trucks multiplied by the length of arterial roads (truck-meters)'
                ) |>
  add_col_attrs(truck_meters_moving,
                title = 'truck meters moving',
                description = 'average daily number of trucks multiplied by the length of interstates, expressways, and freeways (truck-meters)'
                ) |>
  add_col_attrs(evi_500,
                title = 'evi 500',
                description = 'average enhanced vegetation index within a 500 meter buffer radius'
                ) |>
  add_col_attrs(evi_1500,
                title = 'evi 1500',
                description = 'average enhanced vegetation index within a 1500 meter buffer radius'
                ) |>
  add_col_attrs(evi_2500,
                title = 'evi 2500',
                description = 'average enhanced vegetation index within a 2500 meter buffer radius'
                ) |>
  add_col_attrs(drive_time,
                title = 'drive time',
                description = 'drive time in minutes (in 6 minute intervals, ">60" if more than 1 hour drive time)'
                ) |>
  add_col_attrs(distance,
                title = 'distance',
                description = 'distance in meters'
                )

saveRDS(d, "data/exact_location_geomarkers.rds")
