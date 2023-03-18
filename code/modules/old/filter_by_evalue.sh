###############################################################################
# 1. Set env
###############################################################################

set -o pipefail 

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
Usage: ./hmmsearch_runner.bash <options>
--help                          print this help
--config_file CHAR              configuratoin file
--filtering_evalue NUM          maximum evalue used to filter sequences                
--input_file CHAR               fasta file to filter
--output_file CHAR              name of output file
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
  --filtering_evalue)
  if [[ -n "${2}" ]]; then
    FILTERING_EVALUE="${2}"
    shift
  fi
  ;;
  --filtering_evalue=?*)
  FILTERING_EVALUE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --filtering_evalue=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;    
#############
  --output_file)
  if [[ -n "${2}" ]]; then
    OUTPUT_FILE="${2}"
    shift
  fi
  ;;
  --output_file=?*)
  OUTPUT_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --output_file=) # Handle the empty case
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
# 4. Source config file
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

if [[ -z "${OUTPUT_FILE}" ]]; then
  OUTPUT_FILE="01-potential_domains_filtered.fna"
fi

###############################################################################
# 6. Check input and case
###############################################################################

if [[ ! -a "${INPUT_FILE}" ]]; then
  echo "Missing input file"
  echo "Use the \"--input_file\" flag to set the input (amino acid) fasta"
  exit 1
fi

###############################################################################
# 7. Create outpt directory and deifne output files
###############################################################################

if [[ "${OVERWRITE}" == "f" ]]; then
  if [[ -a "${OUTPUT_FILE}" ]]; then
    echo "${OUTPUT_FILE} already exists"
    echo "Use \"--overwirte t\" to overwirte"
    exit 1
  fi
fi

###############################################################################
### 7. Filter fasta file
###############################################################################

awk -v OFS="\t" -v filtering_evalue="${FILTERING_EVALUE}" '{

  if ($1 ~ "^>") {
    
    flag = 0
    split($0,header,"|")
    evalue=header[2]
      
    if (evalue <= filtering_evalue) {
      flag = 1
    }
  }
    
  if (flag == 1) { 
    print $0
  }
  
}' "${INPUT_FILE}" > "${OUTPUT_FILE}"

if [[ $? != "0" ]]; then
  echo "awk command to parse hmmsearch output failed"
  exit 1
fi

###############################################################################
# 9. Check point
###############################################################################

NSEQ=$(egrep -c ">" "${OUTPUT_FILE}")

if [[ "${NSEQ}" -lt 100 ]]; then
  echo "Warning: ${NSEQ} sequences passed the GA"
fi  

###############################################################################
# 10. Exit
###############################################################################

echo -e "filter_by_evalue.bash $(basename ${INPUT_FILE})\texited successfully"
exit 0
