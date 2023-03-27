all: data/riseup_geomarker_pipeline_output.rds

data/cleaned_addresses.rds: R/00_import_clean_data.R data-raw/HospitalAdmissions.csv
		Rscript R/00_import_clean_data.R

data/geocodes.rds: R/01_geocode.R data/cleaned_addresses.rds
		Rscript R/01_geocode.R

data/exact_location_geomarkers.rds: data/geocodes.rds R/02_exact_location_geomarkers.R
	Rscript R/02_exact_location_geomarkers.R

data/census_tract_level_data.rds: data/geocodes.rds R/03_census_tract_level_data.R
	Rscript R/03_census_tract_level_data.R

# data/nlcd.rds: data/geocodes.rds R/add_nlcd.R
	# Rscript R/add_nlcd.R

data/parcel_data.rds: data/geocodes.rds R/05_add_parcel_data.R
	Rscript R/05_add_parcel_data.R

data-raw/daily_data.rds: R/06_get_time_data.R
	Rscript R/06_get_time_data.R

data/riseup_geomarker_pipeline_output.rds: R/07_join_data.R data/geocodes.rds data/exact_location_geomarkers.rds data/census_tract_level_data.rds data/parcel_data.rds data-raw/daily_data.rds
	Rscript R/07_join_data.R

