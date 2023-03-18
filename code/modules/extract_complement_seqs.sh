###############################################################################
# 1. Set env
###############################################################################

set -o pipefail 

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
Usage: ./hmmsearch_runner.sh <options>
--help                          print this help
--confg_file CHAR               configuration file
--input_file CHAR               hmmsearch output file (i.e., domtblout) to get sequences ids, coords, evalu and domains
--genome_cds_file CHAR          genome cds fna file from whith sequences are extraced
--output_dir CHAR               directory to output generated data
--overwrite t|f                 overwrite directory (defaould f)
EOF
}

###############################################################################
# 3. Parse input parameters
###############################################################################

while :; do
  case "${1}" in
  --help) # Call a "show_help" function to display a synopsis, then exit.
  show_usage
  exit 1;
  ;;
#############
  --config_file)
  if [[ -n "${2}" ]]; then
    CONFIG_FILE="${2}"
    shift
  fi
  ;;
  --config_file=?*)
  CONFIG_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --config_file=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;     
#############
  --genome_cds_file)
  if [[ -n "${2}" ]]; then
    GENOME_CDS_FILE="${2}"
    shift
  fi
  ;;
  --genome_cds_file=?*)
  GENOME_CDS_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --genome_cds_file=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;   
#############
  --input_file)
  if [[ -n "${2}" ]]; then
    INPUT_FILE="${2}"
    shift
  fi
  ;;
  --input_file=?*)
  INPUT_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input_file=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --output_dir)
  if [[ -n "${2}" ]]; then
    OUTPUT_DIR="${2}"
    shift
  fi
  ;;
  --output_dir=?*)
  OUTPUT_DIR="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --output_dir=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  --overwrite)
  if [[ -n "${2}" ]]; then
    OVERWRITE="${2}"
    shift
  fi
  ;;
  --overwrite=?*)
  OVERWRITE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --overwrite=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
############ End of all options.
  --)       
  shift
  break
  ;;
  -?*)
  printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
  ;;
  *) # Default case: If no more options, then break out of the loop.
  break
  esac
  shift
done  

###############################################################################
# 4. Source conifg file
###############################################################################

source "${CONFIG_FILE}" 
if [[ $? -ne 0 ]]; then
  echo "source configuration file failed"
  exit 1
fi  

###############################################################################
# 5. Define defaults
###############################################################################

if [[ -z "${OVERWRITE}" ]]; then
  OVERWRITE="f"
fi  

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="extracted_doms_output_dir"
fi

###############################################################################
# 6. Check input and case
###############################################################################

if [[ ! -a "${INPUT_FILE}" ]]; then
  echo "Missing input file"
  echo "Use the \"--input_file\" flag to set the inpute (amino acid) fasta"
  exit 1
fi

if [[ ! -a "${GENOME_CDS_FILE}" ]]; then
  echo "No genome file"
  echo "Use the \"--genome_file\" flag to set the genome file"
  exit 1
fi  

###############################################################################
# 7. Create outpt directory and deifne output files
###############################################################################

if [[ "${OVERWRITE}" == "t" ]]; then
  if [[ -d "${OUTPUT_DIR}" ]]; then
    rm -r "${OUTPUT_DIR}"
    mkdir "${OUTPUT_DIR}"
  else 
  mkdir "${OUTPUT_DIR}"
  fi
fi

if [[ "${OVERWRITE}" == "f" ]]; then
  if [[ -d "${OUTPUT_DIR}" ]]; then
    echo "${OUTPUT_DIR} already exists"
    echo "Use \"--overwirte t\" to overwirte"
    exit 1
  else
    mkdir "${OUTPUT_DIR}"
  fi
fi

###############################################################################
# 8. Parse hmmsearch output
###############################################################################

awk -v OFS="\t" '{

  if ($0 !~ "^#") {
    id=gensub("_1$","","g",$1)
    hmm=$5
    i_evalue=$13
    ali_start_nuc=($18-1)*3
    ali_end_nuc=$19*3
    print id, ali_start_nuc, ali_end_nuc, i_evalue, hmm
  }
  
}' "${INPUT_FILE}" > "${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv"

if [[ $? != "0" ]]; then
  echo "awk command to parse hmmsearch output failed"
  exit 1
fi

if [[ ! -s "${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv" ]]; then
  echo "No hits found in input file ${INPUT_FILE}"
  exit 0
fi  

###############################################################################
# 9. Get seqs list
###############################################################################

awk '{print $1}' "${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv" | \
sort | uniq > \
"${OUTPUT_DIR}/tmp-02_seqs.list"

if [[ $? -ne "0" ]]; then
  echo "awk command to cread seq id list failed"
  exit 1
fi  

###############################################################################
# 10. Extract complement sequences
###############################################################################
    
"${filterbyname}" \
in="${GENOME_CDS_FILE}" \
names="${OUTPUT_DIR}/tmp-02_seqs.list" \
out="${OUTPUT_DIR}/negative_doms.fna" \
include=f \
overwrite=t 2> /dev/null

if [[ $? -ne "0" ]]; then
  echo "filterbyname command failed"
  exit 1
fi  

###############################################################################
# 11. Format header: remove lcl|
###############################################################################

sed -i "s/>lcl|\([^\ ]\+\).*/>\\1|NA|NA|negative_domain/" \
"${OUTPUT_DIR}/negative_doms.fna"

if [[ $? -ne 0 ]]; then
  echo "sed command to format header failed"
  exit 1
fi
  
###############################################################################
# 12. Check point: total sum
###############################################################################

NSEQ_TOTAL_REF=$(egrep -c ">" "${GENOME_CDS_FILE}")
NSEQ_NEGATIVE=$(egrep -c ">" "${OUTPUT_DIR}/negative_doms.fna")
NSEQ_REMOVED=$(wc -l < "${OUTPUT_DIR}/tmp-02_seqs.list")

NSEQ_TOTAL_QUERY=$(echo "${NSEQ_NEGATIVE} + ${NSEQ_REMOVED}" |bc)
                  
if [[ "${NSEQ_TOTAL_REF}" -ne "${NSEQ_TOTAL_QUERY}" ]]; then
  echo "Check point 2 failed: total  negative domains"
  exit 1
fi  

###############################################################################
# 13. Clean
###############################################################################

rm "${OUTPUT_DIR}"/tmp-*

if [[ $? -ne "0" ]]; then
  echo "Clean command failed"
  exit 1
fi

###############################################################################
# 14. Exit
###############################################################################

echo -e "extract_complement_seq.sh $(basename ${INPUT_FILE})\texited successfully"
exit 0
