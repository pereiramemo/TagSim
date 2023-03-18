###############################################################################
### 1. Set env
###############################################################################

set -o pipefail 
source "${HOME}/workspace/dev/resfam/scripts/conf.sh"

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
Usage: ./hmmsearch_runner.sh <options>
--help                          print this help
--hmm_file CHAR                 HMM file to annotate reference sequences
--input_file CHAR               input amino acid fasta file (i.e., .faa)
--nslots NUM                    number of threads used (default 4)
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
  --hmm_file)
  if [[ -n "${2}" ]]; then
    HMM_FILE="${2}"
    shift
  fi
  ;;
  --hmm_file=?*)
  HMM_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --hmm_file=) # Handle the empty case
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
  --nslots)
  if [[ -n "${2}" ]]; then
    NSLOTS="${2}"
    shift
  fi
  ;;
  --nslots=?*)
  NSLOTS="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --nslots=) # Handle the empty case
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
# 4. Define defaults
###############################################################################

if [[ -z "${NSLOTS}" ]]; then
  NSLOTS="1"
fi  

if [[ -z "${OVERWRITE}" ]]; then
  OVERWRITE="f"
fi  

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="$(basename ${INPUT_FILE} .faa)_hmmsearch_output_dir"
fi

###############################################################################
# 5. Check input and case
###############################################################################

if [[ ! -a "${INPUT_FILE}" ]]; then
  echo "No input_file"
  echo "Use the \"--input_file\" flag to set the inpute (amino acid) fasta"
  exit 1
fi  

if [[ -z "${HMM_FILE}" ]]; then
  echo "Missing HMM file"
  echo "Use \"--input_hmm\" flag to set the HMM file"
  exit 1
fi  

###############################################################################
# 6. Create outpt directory and deifne output files
###############################################################################

DOMTBLOUT="${OUTPUT_DIR}/$(basename ${INPUT_FILE} | \
          sed "s/.faa\|.fasta|.fa/.domtblout/")"
OUTPUT_FILE="${OUTPUT_DIR}/$(basename ${INPUT_FILE} | \
             sed "s/.faa\|.fasta|.fa/.hmmout/")"
                          
if [[ -a  "${DOMTBLOUT}" ]] || [[ -a "${OUTPUT_FILE}" ]]; then
  if [[ "${OVERWRITE}" == "f" ]]; then
    echo "${DOMTBLOUT} or ${OUTPUT_FILE} already exits"
    echo "Use \"--overwirte t\" to overwirte"
    exit 1
  else 
    rm "${DOMTBLOUT}"
    rm "${OUTPUT_FILE}"
  fi   
fi

###############################################################################
# 7. Run hmmsearch
###############################################################################

"${hmmsearch}" \
-E 30 \
--domE 30 \
--domtblout "${DOMTBLOUT}" \
--cpu "${NSLOTS}" \
"${HMM_FILE}" "${INPUT_FILE}" > "${OUTPUT_FILE}"
    
if [[ $? -ne "0" ]]; then
  echo "hmmsearch for ${CASE} failed"
  exit 1
fi    
###############################################################################
# 8. Exit
###############################################################################

echo -e "$(basename ${INPUT_FILE})\texited successfully"
exit 0
