library(dplyr)
library(dht)
library(codec)

d <- readRDS("data/cleaned_addresses.rds")

# geocode
d <- d |>
  rename(address = parsed_address) |>
  dht::degauss_run("geocoder", "3.3.0", quiet = FALSE) |>
  rename(parsed_address = address) |>
  select(-starts_with("matched_")) |>
  select(-score, -precision)

# add column attributes
d <- d |>
  add_col_attrs(parsed_address,
    title = "Parsed Address",
    description = "parsed address"
  ) |>
  add_col_attrs(hamilton_zip,
    title = "Hamilton ZIP Code",
    description = "TRUE if ZIP code was matched to a ZIP code in cincy::zcta_tigris_2020"
  ) |>
  add_col_attrs(lat,
    title = "Latitude",
    description = "geocoded latitude coordinate"
  ) |>
  add_col_attrs(lon,
    title = "Longitude",
    description = "geocoded longitude coordinate"
  ) |>
  add_col_attrs(geocode_result,
    title = "Geocode Result",
    description = "character string summarizing the geocoding result (geocoded: the address was geocoded with a precision of either range or street and a score of 0.5 or greater; imprecise_geocode: the address was geocoded, but results were suppressed because the precision was intersection, zip, or city and/or the score was less than 0.5; po_box: the address was not geocoded because it is a PO Box; cincy_inst_foster_addr: the address was not geocoded because it is a known institutional address, not a residential address; non_address_text: the address was not geocoded because it was blank or listed as “foreign”, “verify”, or “unknown”)"
  )

# 2010 census block group and tract
d <-
  d |>
  degauss_run("census_block_group", "0.6.0", argument = "2010", quiet = FALSE) |>
  add_col_attrs(census_block_group_id_2010,
    title = "2010 Census Block Group identifer"
  ) |>
  add_col_attrs(census_tract_id_2010,
    title = "2010 Census Tract identifer"
  )

# 2020 census block group and tract
d <- d |> degauss_run("census_block_group", "0.6.0", argument = "2020", quiet = FALSE)

add_col_attrs(census_block_group_id_2020,
  title = "2020 Census Block Group identifer"
) |>
  add_col_attrs(census_tract_id_2020,
    title = "2020 Census Tract identifer"
  )

saveRDS(d, "data/geocodes.rds")
