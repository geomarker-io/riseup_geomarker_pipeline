all: data/hospital_admission_joined_nonparcel.rds data/hospital_admission_joined_data.rds data/hospital_admission_joined_parcel_nonparcel_temporal.rds
	echo "you did it!"

data/cleaned_addresses.rds: R/00_import_clean_data.R `data-raw/Hospital Admissions.csv`
		Rscript R/00_import_clean_data.R

data/geocodes.rds: R/01_geocode.R data/cleaned_addresses.rds
		Rscript R/01_geocode.R

data/exact_location_geomarkers.rds: data/geocodes.rds R/02_exact_location_geomarkers.R
	Rscript R/02_exact_location_geomarkers.R

data/census_tract_level_data.rds: data/geocodes.rds R/03_census_tract_level_data.R
	Rscript R/03_census_tract_level_data.R

data/nlcd.rds: data/geocodes.rds R/add_nlcd.R
	Rscript R/add_nlcd.R

data/parcel_data.rds: data/geocodes.rds R/add_parcel_data.R
	Rscript R/add_parcel_data.R

data/daily_data.rds: R/get_time_data.R
	Rscript R/get_time_data.R

data/hospital_admission_joined_nonparcel.rds: data/hospital_admission.rds data/degauss_geomarker_library.rds data/nlcd.rds data/census_tract_lvl_data.rds R/join_nonparcel_data.R
	Rscript R/join_nonparcel_data.R

data/hospital_admission_joined_parcel.rds: data/hospital_admission.rds data/parcel_data.rds R/join_parcel_data.R
	Rscript R/join_parcel_data.R

data/hospital_admission_joined_temporal_data.rds: data/hospital_admission.rds data/daily_data.rds R/join_temporal_data.R
	Rscript R/join_temporal_data.R

data/hospital_admission_joined_parcel_nonparcel.rds: data/hospital_admission_joined_nonparcel.rds data/parcel_data.rds R/join_parcel_nonparcel.R
	Rscript R/join_parcel_nonparcel.R

data/hospital_admission_joined_parcel_nonparcel_temporal.rds: data/hospital_admission_joined_parcel_nonparcel.rds data/daily_data.rds R/join_parcel_nonparcel_temporal.R
	Rscript R/join_parcel_nonparcel_temporal.R
