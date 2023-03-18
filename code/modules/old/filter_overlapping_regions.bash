#!/bin/bash

set -o pipefail

###############################################################################
### 1. Load environment
###############################################################################

WORKDIR="/bioinf/projects/megx/domain2class_predictions/synthetic_metagenomes/\
data_simulations/tgs_cds_simulations/"
source "${WORKDIR}/scripts/conf.bash"
source ~/.profile
module load bedtools

CASE="${1}"

###############################################################################
### 2. Get genome names, and dirs
###############################################################################

GENOME_NAME=$(sed -n "${SGE_TASK_ID}"p "${REFCDSFNALIST}")
GENOME_NAME_SHORT=${GENOME_NAME/_cds_from_genomic.fna}
GENOME_FILE=$(ls "${OUTPUT_DIR}/ref_cds/${GENOME_NAME}")
CASE_DIR="${OUTPUT_DIR}/ref_cds_annot/${GENOME_NAME_SHORT}/${CASE}/"

###############################################################################
### 3. Get headers
###############################################################################

egrep ">" "${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs.fna" | \
sed "s/>//" > "${CASE_DIR}/tmp_headers-01.list"

if [[ $? -ne "0" ]]; then
  echo "egrep headers failed"
  exit 1
fi

###############################################################################
### 4. Sort headers by evalue
###############################################################################

sort -g -k3 -t "|" "${CASE_DIR}/tmp_headers-01.list" > \
"${CASE_DIR}/tmp_headers-02.list"

if [[ $? -ne "0" ]]; then
  echo "sort headers failed"
  exit 1
fi

###############################################################################
### 5. Find overlapping regions
###############################################################################

"${SCRIPTS}/overlapping_region_finder.pl" \
"${CASE_DIR}/tmp_headers-02.list" > \
"${CASE_DIR}/tmp_overlapped_seqs.output"

if [[ $? != "0" ]]; then
  echo "overlapping_region_finder.pl failed"
  exit 1
fi

###############################################################################
### 6. Format overlapped headers output
###############################################################################

cut -f3 "${CASE_DIR}/tmp_overlapped_seqs.output" | \
sort | uniq > "${CASE_DIR}/tmp_overlapped_headers.list"

if [[ $? != "0" ]]; then
  echo "formatting tmp_overlapped_seqs.output failed"
  exit 1
fi

###############################################################################
### 7. Remove reads with overlapping regions
###############################################################################

"${filterbyname}" \
in="${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs.fna" \
out="${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs_nonoverlap.fna" \
names="${CASE_DIR}/tmp_overlapped_headers.list" \
include=f \
overwrite=t

if [[ $? != "0" ]]; then
  echo "filerbyname to remove overlapping regions failed"
  exit 1
fi

###############################################################################
### 8. Check length
###############################################################################

"${bbduk}" \
in="${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs_nonoverlap.fna" \
out="${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs_filtered.fna" \
threads="${NSLOTS}" \
minlength=60 \
overwrite=t \
fastawrap=0

if [[ $? != "0" ]]; then
  echo "bbduk check length failed"
  exit 1
fi

###############################################################################
### 7. Control
###############################################################################

NSEQ_TOTAL=$(egrep -c ">" "${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs.fna")
NSEQ_NONOVERLAP=$(egrep -c ">" "${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs_nonoverlap.fna")
NSEQ_2REMOVE=$(wc -l < "${CASE_DIR}/tmp_overlapped_headers.list")

NSEQ_TOTAL_REF=$(echo "${NSEQ_NONOVERLAP} + ${NSEQ_2REMOVE}" | bc)

if [[ "${NSEQ_TOTAL}" -ne  "${NSEQ_TOTAL_REF}" ]]; then
  echo "removed overlapping seqs don't add up"
  exit 1
fi

###############################################################################
### 8. clean
###############################################################################

rm "${CASE_DIR}"/tmp_*

if [[ $? != "0" ]]; then
  echo "clean failed"
  exit 1
fi
