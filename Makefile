.PHONY: daily daily_data clean geocode tract geomark nlcd parcel all

all: daily clean geocode tract geomark nlcd parcel

clean: data/cleaned_addresses.rds
geocode: data/geocodes.rds
tract: data/census_tract_level_data.rds
geomark: data/exact_location_geomarkers.rds
nlcd: data/nlcd.rds
parcel: data/parcel.rds
daily: data/daily.rds 
merge: data/riseup_geomarker_pipeline_output.rds tabular_data_resource

data/riseup_geomarker_pipeline_output.rds: clean geocode tract geomark nlcd parcel daily R/join_all.R
	Rscript R/join_all.R

tabular_data_resource: data/riseup_geomarker_pipeline_output.rds
	R -e "codec::write_tdr_csv(readRDS('data/riseup_geomarker_pipeline_output.rds'), 'data')"

daily_data: data-raw/daily_aqi.rds data-raw/daily_pollen_mold.rds data-raw/daily_weather.rds

data/daily.rds: R/daily.R data/cleaned_addresses.rds daily_data
	Rscript R/daily.R
data-raw/daily_aqi.rds: data-raw/daily_aqi.R
	Rscript data-raw/daily_aqi.R

data-raw/daily_pollen_mold.rds: data-raw/daily_pollen_mold.R
	Rscript data-raw/daily_pollen_mold.R

data-raw/daily_weather.rds: data-raw/daily_weather.R
	Rscript data-raw/daily_weather.R

data/cleaned_addresses.rds: R/import_clean_data.R data/HospitalAdmissions.csv
	Rscript R/import_clean_data.R

data/geocodes.rds: R/geocode.R data/cleaned_addresses.rds
	Rscript R/geocode.R

data/census_tract_level_data.rds: data/geocodes.rds R/census_tract_level_geomarkers.R
	Rscript R/census_tract_level_geomarkers.R

data/exact_location_geomarkers.rds: data/geocodes.rds R/exact_location_geomarkers.R
	Rscript R/exact_location_geomarkers.R

data/nlcd.rds: data/geocodes.rds R/nlcd_geomarkers.R
	Rscript R/nlcd_geomarkers.R

data/parcel.rds: data/geocodes.rds R/parcel_geomarkers.R
	Rscript R/parcel_geomarkers.R
