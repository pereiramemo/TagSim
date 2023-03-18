#!/bin/bash

set -o pipefail

###############################################################################
### 1. load environment
###############################################################################

WORKDIR="/bioinf/projects/megx/domain2class_predictions/synthetic_metagenomes/\
data_simulations/tgs_cds_simulations/"
source "${WORKDIR}/scripts/conf.bash"

CASE="negative"

###############################################################################
### 2. get genome names, and dirs
###############################################################################

GENOME_NAME=$(sed -n "${SGE_TASK_ID}"p "${REFCDSFAALIST}")
GENOME_NAME_SHORT=${GENOME_NAME/_cds_from_genomic.faa}
GENOME_FILE=$(ls "${OUTPUT_DIR}/ref_cds_annot/${GENOME_NAME_SHORT}/${GENOME_NAME}")
CASE_DIR=$(dirname "${GENOME_FILE}")/"${CASE}"

###############################################################################
### 3. run hmmscan
###############################################################################

cat "${HMMLIST}" | \
while read LINE; do

  HMM="${HMM_DIR}/${LINE}"
  HMM_NAME="${LINE/.hmm/}"
  OUTPUT_ANNOT="${CASE_DIR}/${GENOME_NAME/.faa/}_DOM_${HMM_NAME}.hout"

  "${hmmscan}" \
  --cpu "${NSLOTS}" \
  -E 30 \
  --domE 30 \
  --domtblout "${OUTPUT_ANNOT}" \
  "${HMM}" "${GENOME_FILE}"

  if [[ $? != "0" ]]; then
    echo "hmmsearch negative case failed"
    exit 1
  fi

done

