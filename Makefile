all: data/riseup_geomarker_pipeline_output/riseup_geomarker_pipeline_output.csv data/riseup_geomarker_pipeline_output/tabular-data-resource.yaml

data/riseup_geomarker_pipeline_output/riseup_geomarker_pipeline_output.csv data/riseup_geomarker_pipeline_output/tabular-data-resource.yaml: data/riseup_geomarker_pipeline_output.rds DESCRIPTION
	R --quiet -e "fr::write_fr_tdr(readRDS('data/riseup_geomarker_pipeline_output.rds'), 'data')"

data/riseup_geomarker_pipeline_output.rds: DESCRIPTION data/cleaned_addresses.rds data/geocodes.rds data/census_tract_level_data.rds data/traffic.rds data/greenness.rds data/drivetime.rds data/nlcd.rds data/parcel.rds data/daily.rds R/join_all.R
	Rscript R/join_all.R

data/cleaned_addresses.rds: R/import_clean_data.R data/HospitalAdmissions.csv
	Rscript R/import_clean_data.R

data/geocodes.rds: R/geocode.R data/cleaned_addresses.rds
	Rscript R/geocode.R

data/census_tract_level_data.rds: data/geocodes.rds R/census_tract_level_geomarkers.R
	Rscript R/census_tract_level_geomarkers.R

data/parcel.rds: data/cleaned_addresses.rds data/census_tract_level_data.rds R/parcel.R
	Rscript R/parcel.R

data/drivetime.rds: data/geocodes.rds R/drivetime.R
	Rscript R/drivetime.R

data/greenness.rds: data/geocodes.rds R/greenness.R
	Rscript R/greenness.R

data/traffic.rds: data/geocodes.rds R/traffic.R
	Rscript R/traffic.R

data/nlcd.rds: data/geocodes.rds R/nlcd.R
	Rscript R/nlcd.R

daily_raw = data-raw/daily_aqi.rds data-raw/daily_pollen_mold.rds data-raw/daily_weather.rds

data/daily.rds: R/daily.R data/cleaned_addresses.rds $(daily_raw)
	Rscript R/daily.R

$(daily_raw): data-raw/%.rds: data-raw/%.R
	Rscript $<
