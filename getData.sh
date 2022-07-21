#!/bin/bash
    set -e
    set -u
    set -o pipefail

addr_infile=$1
addr_outfile=$2

echo "script name: $0"
echo "address raw file: ${addr_infile}"
echo "address clean file: ${addr_outfile}"

# organize address
./scripts/get_address.R ${addr_infile} ${addr_outfile}

# geocoder
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/geocoder:3.2.0 ./data/${addr_outfile}.csv

# dep-index
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/dep_index:0.2.0 ./data/${addr_outfile}_geocoder_3.2.0_score_threshold_0.5.csv

# roads
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/roads:0.2.1 ./data/${addr_outfile}_geocoder_3.2.0_score_threshold_0.5_dep_index_0.2.0.csv

# aadt
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/aadt:0.2.0 ./data/${addr_outfile}_geocoder_3.2.0_score_threshold_0.5_dep_index_0.2.0_roads_0.2.1_400m_buffer.csv

# greenspace
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/greenspace:0.3.0 ./data/${addr_outfile}_geocoder_3.2.0_score_threshold_0.5_dep_index_0.2.0_roads_0.2.1_400m_buffer_aadt_0.2.0_400m_buffer.csv

# drivetime
docker run --rm -v "$PWD":/tmp ghcr.io/degauss-org/drivetime:1.1.0 ./data/${addr_outfile}_geocoder_3.2.0_score_threshold_0.5_dep_index_0.2.0_roads_0.2.1_400m_buffer_aadt_0.2.0_400m_buffer_greenspace_0.3.0.csv cchmc



