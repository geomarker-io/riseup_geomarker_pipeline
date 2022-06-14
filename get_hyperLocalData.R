library(sf) # Linking to GEOS 3.9.1, GDAL 3.2.1, PROJ 7.2.1;
library(dplyr)

if (!file.exists("data-raw/HamParcels.gdb")) {
  tmp <- tempfile(fileext = ".zip")
  download.file(glue::glue("http://cagis.org/Opendata/Auditor/HamParcels.gdb.zip"), tmp)
  unzip(tmp, exdir = "data-raw")
}

d <-
  st_read(dsn = "data-raw/HamParcels.gdb", layer = "HamMergedParcelsWCondoAtts") |>
  st_zm(drop = TRUE, what = "ZM")

d_data <-
  d |>
  st_cast("MULTIPOLYGON") |>
  st_drop_geometry() |>
  as_tibble() |>
  transmute(
    parcel_id = PROPTYID,
    owner_lastname = OWNER6,
    owner_name_part1 = OWNNM1,
    owner_name_part2 = OWNNM2,
    owner_address_part1 = OWNAD1,
    owner_address_part2 = OWNAD1A,
    owner_address_part3 = OWNAD2,
    owner_address_city = OWNADCITY,
    owner_address_state = OWNADSTATE,
    owner_address_zipcode = OWNADZIP,
    property_addr_number = ADDRNO,
    property_addr_street = ADDRST,
    property_addr_sf = ADDRSF,
    tax_district = TAXDST_DIS,
    school_district = SCHOOL_CODE_DIS,
    apraisal_area = APPRAR_DIS,
    market_land_value = MKTLND,
    market_improvement_value = MKTIMP,
    market_total_value = MKT_TOTAL_VAL,
    current_agriculture_use_value = MKTCAU,
    auditor_land_use_code = CLASS,
    existing_land_use_code = EXLUCODE,
    sale_date = SALDAT,
    last_sale_amount = SALAMT,
    acreage = ACREDEED,
    homestead = HMSD_FLAG,
    rental_registration = RENT_REG_FLAG,
    RED_25_FLAG = RED_25_FLAG,
    DIV_FLAG = DIV_FLAG,
    special_assessments = SPLFLG,
    new_house = NEWFLG,
    foreclosure = FORECL_FLAG,
    annual_taxes = ANNUAL_TAXES,
    taxes_paid = TAXES_PAID,
    delinquent_taxes = DELQ_TAXES,
    delinquent_taxes_paid = DELQ_TAXES_PD,
    unit = UNIT,
    condoname = CONDONAME,
    phase = PHASE,
    percent_own = PERCENTOWN
  )

d_geom <-
  d |>
  st_as_sfc() |>
  st_cast("MULTIPOLYGON") |>
  st_as_sf()

d <-
  bind_cols(d_data, d_geom) |>
  st_as_sf()

## mapview::mapviewOptions(fgb = FALSE)
## slice_sample(d, n = 1000) |>
##   mapview::mapview()

# save RDS file
saveRDS(d, "hamilton_parcels.rds")

# save gpkg file
st_write(d, "hamilton_parcels.gpkg")

# save CSV file
readr::write_csv(d, "hamilton_parcels.csv")

