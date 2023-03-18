#!/bin/bash

set -o pipefail

###############################################################################
### 1. load environment
###############################################################################

WORKDIR="/bioinf/projects/megx/domain2class_predictions/synthetic_metagenomes/\
data_simulations/tgs_cds_simulations/"
source "${WORKDIR}/scripts/conf.bash"

###############################################################################
### 2. get genome names, and dirs
###############################################################################

CASE="negative"
GENOME_NAME=$(sed -n "${SGE_TASK_ID}"p "${REFCDSFNALIST}")
GENOME_NAME_SHORT=${GENOME_NAME/_cds_from_genomic.fna}
GENOME_FILE=$(ls "${OUTPUT_DIR}/ref_cds/${GENOME_NAME}")
CASE_DIR="${OUTPUT_DIR}/ref_cds_annot/${GENOME_NAME_SHORT}/${CASE}"

###############################################################################
### 3. extract sequences
###############################################################################

cat "${HMMLIST}" | \
while read LINE; do

  HMM_NAME="${LINE/.hmm/}"
  HMM_FILE="${CASE_DIR}/${GENOME_NAME_SHORT}_cds_from_genomic_DOM_${HMM_NAME}".hout

  if egrep -qw  "^${HMM_NAME}" "${HMM_FILE}"; then
    egrep -w "^${HMM_NAME}" "${HMM_FILE}" | \
    awk -v OFS="\t" '{
    sub(/_1$/,"",$4);
    print $4}' > "${CASE_DIR}/tmp_${HMM_NAME}_seqs.list"

    if [[ $? != "0" ]]; then
      echo "awk command to create seqs.list failed ${HMM}"
      exit 1
    fi
  fi

done

###############################################################################
### 4. Conctenate
###############################################################################

cat "${CASE_DIR}"/tmp_*_seqs.list | sort | uniq > "${CASE_DIR}/tmp_all_dom_seqs.list"

if [[ $? != "0" ]]; then
  echo "cat all negative failed"
  exit 1
fi

###############################################################################
### 5. Remove seqs
###############################################################################

"${filterbyname}" \
in="${GENOME_FILE}" \
names="${CASE_DIR}/tmp_all_dom_seqs.list" \
out="${CASE_DIR}/${GENOME_NAME_SHORT}_nodom_seqs.fna" \
include=f \
overwrite=t

if [[ $? != "0" ]]; then
  echo "filterbyname to exclude sequences failed"
  exit 1
fi

###############################################################################
### 6. format header: add nodomain tag
###############################################################################

sed -i "s/>\([^\ ]\+\)\ .*/>\1\|nodomain/" \
"${CASE_DIR}/${GENOME_NAME_SHORT}_nodom_seqs.fna"

if [[ $? -ne "0" ]]; then
  echo "sed command to format header failed"
  exit 1
fi

###############################################################################
### 7. control output
###############################################################################

N_DOM=$(wc -l < "${CASE_DIR}/tmp_all_dom_seqs.list")
N_TOT=$(egrep -c ">" "${GENOME_FILE}")
N_OUT=$(egrep -c ">" "${CASE_DIR}/${GENOME_NAME_SHORT}_nodom_seqs.fna")
N_CONTROL=$(echo ${N_DOM} + ${N_OUT} | bc -l)

if [[ "${N_TOT}" -ne "${N_CONTROL}" ]]; then
  echo "Warning: count control failed"
  echo "ouput:${N_OUT}; domain:${N_DOM}; total=${N_TOT}; control:${N_CONTROL}"
  exit 1
fi

###############################################################################
### 8. Check length
###############################################################################

"${bbduk}" \
in="${CASE_DIR}/${GENOME_NAME_SHORT}_nodom_seqs.fna" \
out="${CASE_DIR}/${GENOME_NAME_SHORT}_nodom_seqs_filtered.fna" \
threads="${NSLOTS}" \
minlength=60 \
overwrite=t \
fastawrap=0

if [[ $? != "0" ]]; then
  echo "bbduk command to check length failed"
  exit 1
fi

###############################################################################
### 9. clean
###############################################################################

rm "${CASE_DIR}"/tmp_*

if [[ $? != "0" ]]; then
  echo "clean failed"
  exit 1
fi
