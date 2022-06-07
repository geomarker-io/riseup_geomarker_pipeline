
library(sf)        # Linking to GEOS 3.9.1, GDAL 3.2.1, PROJ 7.2.1;
library(tidyverse) # tidyverse 1.3.1
library(gdalUtilities)

download.file(url="http://cagis.org/Opendata/Auditor/HamParcels.gdb.zip",
              destfile = "raw-data/HamParcels.gdb.zip",
              mode = "wb")

unzip("raw-data/HamParcels.gdb.zip", exdir = 'raw-data')
unlink("raw-data/HamParcels.gdb.zip")


hamparcels <- st_read(
  dsn = "raw-data/HamParcels.gdb",
  layer = "HamMergedParcelsWCondoAtts"
)
saveRDS(hamparcels, file="data/hamParcels.rds")

# Simple feature collection with 353747 features and 96 fields
# Geometry type: GEOMETRY
# Dimension:     XYZ
# Bounding box:  xmin: 1310122 ymin: 377822.3 xmax: 1471220 ymax: 484976
# z_range:       zmin: 0 zmax: 0
# Projected CRS: NAD83 / Ohio South (ftUS)

# Multiple surface to polygons
ensure_multipolygons <- function(X) {
  tmp1 <- tempfile(fileext = ".gpkg")
  tmp2 <- tempfile(fileext = ".gpkg")
  st_write(X, tmp1)
  ogr2ogr(tmp1, tmp2, f = "GPKG", nlt = "MULTIPOLYGON")
  Y <- st_read(tmp2)
  st_sf(st_drop_geometry(X), geom = st_geometry(Y))
}

hamparcels_polygons <- ensure_multipolygons(hamparcels)
saveRDS(hamparcels_polygons, file="data/hamParcels_polygons.rds")

# plot polygon
pdf("Rplot_hamilton_parcels_06072022.pdf")

  plot(st_geometry(hamparcels_polygons))
  plot(st_geometry(st_centroid(hamparcels_polygons)), pch = 20, col = rgb(red = 0, green = 0, blue = 0, alpha = 0.3))

dev.off()

# convert to a tibble
hamparcels_t <- as_tibble(st_drop_geometry(hamparcels)) %>% 
  select(parcel_id=PROPTYID,
         owner_lastname=OWNER6,
         owner_name_part1=OWNNM1,
         owner_name_part2=OWNNM2,
         owner_address_part1=OWNAD1,
         owner_address_part2=OWNAD1A,
         owner_address_part3=OWNAD2,
         owner_address_city=OWNADCITY,
         owner_address_state=OWNADSTATE,
         owner_address_zipcode=OWNADZIP,
         property_addr_number=ADDRNO,
         property_addr_street=ADDRST,
         property_addr_sf=ADDRSF,
         tax_district=TAXDST_DIS,
         school_district=SCHOOL_CODE_DIS,
         apraisal_area=APPRAR_DIS,
         market_land_value=MKTLND,
         market_improvement_value=MKTIMP,
         market_total_value=MKT_TOTAL_VAL,
         current_agriculture_use_value=MKTCAU,
         auditor_land_use_code=CLASS,
         existing_land_use_code=EXLUCODE,
         sale_date=SALDAT,
         last_sale_amount=SALAMT,
         acreage=ACREDEED,
         homestead=HMSD_FLAG,
         rental_registration=RENT_REG_FLAG,
         RED_25_FLAG=RED_25_FLAG,
         DIV_FLAG=DIV_FLAG,
         special_assessments=SPLFLG,
         new_house=NEWFLG,
         foreclosure=FORECL_FLAG,
         annual_taxes=ANNUAL_TAXES,
         taxes_paid=TAXES_PAID,
         delinquent_taxes=DELQ_TAXES,
         delinquent_taxes_paid=DELQ_TAXES_PD,
         unit=UNIT,
         condoname=CONDONAME,
         phase=PHASE,
         percent_own=PERCENTOWN)

# Descriptive statistics
Hmisc::describe(hamparcels_t)

saveRDS(hamparcels_t, file="data/hamilton_parcels_tibble.rds")



