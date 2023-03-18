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
--config_file CHAR              configuratoin file
--input_file CHAR               fasta file to filter
--input_hmm CHAR                hmm file where to parse the GA values 
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
  --input_hmm)
  if [[ -n "${2}" ]]; then
    INPUT_HMM="${2}"
    shift
  fi
  ;;
  --input_hmm=?*)
  INPUT_HMM="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input_hmm=) # Handle the empty case
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

if [[ ! -a "${INPUT_HMM}" ]]; then
  echo "Missing input hmm"
  echo "Use the \"--input_hmm\" flag to set the input hmm file"
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
# 8. Filter fasta file
###############################################################################

awk -v OFS="\t" -v falg="0" '{

  if (NR == FNR) {
  
    if($1 == "ACC") {
    
      if (flag == 1) {
        print "no consecutive GA fonud"
        exit
      }  
    
      dom=$2
      flag=1
    }
    
    if($1 == "GA") { 
      ga1=$2
      ga2=$3
      array_dom2ga1[dom]=ga1
      array_dom2ga2[dom]=ga2
      flag=0
    }
    
  next;
  }
  
  if ($1 ~ "^>") {
    
    flag2 = 0
    split($0,header,"|")
    score=header[3]
    dom=header[4]
      
    if (score >= array_dom2ga2[dom]) {
      flag2 = 1
    }
  }
    
  if (flag2 == 1) { 
    print $0
  }
  
}' "${INPUT_HMM}" "${INPUT_FILE}" > "${OUTPUT_FILE}"

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

echo -e "filter_by_ga.sh $(basename ${INPUT_FILE})\texited successfully"
exit 0
