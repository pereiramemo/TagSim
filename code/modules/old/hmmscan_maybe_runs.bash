#!/bin/bash

set -o pipefail

###############################################################################
### 1. load environment
###############################################################################

source "${DEV}/resfam/scripts/conf.bash"

CASE="potential_domains"

###############################################################################
### 2. get genome names, and dirs
###############################################################################

GENOME_NAME="${1}"

GENOME_NAME_SHORT=${GENOME_NAME/_cds_from_genomic.faa}
GENOME_FILE=$(ls "${OUTPUT_DIR}/ref_cds_annot/${GENOME_NAME_SHORT}/${GENOME_NAME}")
CASE_DIR=$(dirname "${GENOME_FILE}")/"${CASE}"

###############################################################################
### 3. run hmmsearch
###############################################################################

cat "${HMMLIST}" | \
while read LINE; do

  HMM="${HMM_DIR}/${LINE}"
  HMM_NAME="${LINE/.hmm/}"
  OUTPUT_ANNOT="${CASE_DIR}/${GENOME_NAME/.faa/}_DOM_${HMM_NAME}.hout"

 "${hmmscan}" \
  --cpu "${NSLOTS}" \
  -E 1 \
  --domE 1 \
  --domtblout "${OUTPUT_ANNOT}" \
  "${HMM}" "${GENOME_FILE}"

  if [[ $? != "0" ]]; then
    echo "hmmsearch maybe case failed"
    exit 1
  fi

done

