all: data/riseup_geomarker_pipeline_output/riseup_geomarker_pipeline_output.csv data/riseup_geomarker_pipeline_output/tabular-data-resource.yaml

data/riseup_geomarker_pipeline_output/riseup_geomarker_pipeline_output.csv data/riseup_geomarker_pipeline_output/tabular-data-resource.yaml: data/riseup_geomarker_pipeline_output.rds DESCRIPTION
	R --quiet -e "codec::write_tdr_csv(readRDS('data/riseup_geomarker_pipeline_output.rds'), 'data')"

data/riseup_geomarker_pipeline_output.rds: DESCRIPTION data/cleaned_addresses.rds data/geocodes.rds data/census_tract_level_data.rds data/exact_location_geomarkers.rds data/nlcd.rds data/parcel.rds data/daily.rds R/join_all.R
	Rscript R/join_all.R

data/cleaned_addresses.rds: R/import_clean_data.R data/HospitalAdmissions.csv
	Rscript R/import_clean_data.R

data/parcel.rds: data/cleaned_addresses.rds R/parcel_geomarkers.R
	Rscript R/parcel_geomarkers.R

data/geocodes.rds: R/geocode.R data/cleaned_addresses.rds
	Rscript R/geocode.R

data/census_tract_level_data.rds: data/geocodes.rds R/census_tract_level_geomarkers.R
	Rscript R/census_tract_level_geomarkers.R

data/exact_location_geomarkers.rds: data/geocodes.rds R/exact_location_geomarkers.R
	Rscript R/exact_location_geomarkers.R

data/nlcd.rds: data/geocodes.rds R/nlcd_geomarkers.R
	Rscript R/nlcd_geomarkers.R

daily_raw = data-raw/daily_aqi.rds data-raw/daily_pollen_mold.rds data-raw/daily_weather.rds

data/daily.rds: R/daily.R data/cleaned_addresses.rds $(daily_raw)
	Rscript R/daily.R

$(daily_raw): data-raw/%.rds: data-raw/%.R
	Rscript $<
