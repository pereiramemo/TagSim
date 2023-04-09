###############################################################################
# 1. Set env
###############################################################################

set -o pipefail 

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
Usage: ./tagsim.sh <options>
--help                          print this help
--config_file CHAR              configuration file (default $(dirname $(readlink -f $0))/conf.sh")
--clean t|f                     clean all intermediate files (default f)
--filter_by_evalue t|f          filter positive domains by evalue (default f)
--filter_by_ga t|f              filter positive domains by GA (default f)
--filtering_evalue NUM          maximum evalue used to filter positive domains - only used when "--filter_by_evalue t" (default 0.1)
--hmm_file CHAR                 HMM file to annotate reference sequences
--error_rate NUM                error rate of simulated short read sequences (default 1e-3)
--input_dir CHAR                input CDSs fasta file (.fna). All fasta header must start with >lcl|
--max_evalue                    maximum evalue to consider to filter overlapping hits (default 1)
--nslots NUM                    number of threads used (default 4)
--output_dir CHAR               directory to output generated data
--overwrite t|f                 overwrite directory (defaould f)
--query_field CHAR              field to parse hmmsearch output: accession or name (default accession)
--read_length NUM               comma separated read lengths of simulated short reads (default 100,200,300)
--slide_window NUM              sliding window to extract short reads (default 30bp)
--subsample_n                   subsample negative domains n times the number of potential domains (default 1)
--verbose t|f                   output verbose (default f)
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
  --clean)
  if [[ -n "${2}" ]]; then
    CLEAN="${2}"
    shift
  fi
  ;;
  --clean=?*)
  CLEAN="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --clean=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;    
#############
  --filter_by_evalue)
  if [[ -n "${2}" ]]; then
    FILTER_BY_EVALUE="${2}"
    shift
  fi
  ;;
  --filter_by_evalue=?*)
  FILTER_BY_EVALUE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --filter_by_evalue=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  --filter_by_ga)
  if [[ -n "${2}" ]]; then
    FILTER_BY_GA="${2}"
    shift
  fi
  ;;
  --filter_by_ga=?*)
  FILTER_BY_GA="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --filter_by_ga=) # Handle the empty case
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
  --input_dir)
  if [[ -n "${2}" ]]; then
    INPUT_DIR="${2}"
    shift
  fi
  ;;
  --input_dir=?*)
  INPUT_DIR="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --input_dir=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  --error_rate)
  if [[ -n "${2}" ]]; then
    ERROR_RATE="${2}"
    shift
  fi
  ;;
  --error_rate=?*)
  ERROR_RATE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --error_rate=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;    
#############
  --min_length)
  if [[ -n "${2}" ]]; then
    MIN_LENGTH="${2}"
    shift
  fi
  ;;
  --min_length=?*)
  MIN_LENGTH="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --min_length=) # Handle the empty case
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
#############
  --query_field)
  if [[ -n "${2}" ]]; then
    QUERY_FIELD="${2}"
    shift
  fi
  ;;
  --query_field=?*)
  QUERY_FIELD="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --query_field=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;      
#############
  --read_length)
  if [[ -n "${2}" ]]; then
    READ_LENGTH="${2}"
    shift
  fi
  ;;
  --read_length=?*)
  READ_LENGTH="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --read_length=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;    
#############
  --slide_window)
  if [[ -n "${2}" ]]; then
    SLIDE_WINDOW="${2}"
    shift
  fi
  ;;
  --slide_window=?*)
  SLIDE_WINDOW="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --slide_window=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;      
#############
  --subsample_n)
  if [[ -n "${2}" ]]; then
    SUBSAMPLE_N="${2}"
    shift
  fi
  ;;
  --subsample_n=?*)
  SUBSAMPLE_N="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --subsample_n=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;       
#############
  --verbose)
  if [[ -n "${2}" ]]; then
    VERBOSE="${2}"
    shift
  fi
  ;;
  --verbose=?*)
  VERBOSE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --verbose=) # Handle the empty case
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
# 4. Check mandatory parameters
###############################################################################

if [[ ! -d "${INPUT_DIR}" ]]; then
  echo "Missing input dir"
  echo "Use \"--input_dir\" to set the input directory"
  exit 1
fi

N_GENOMES=$(ls "${INPUT_DIR}/"*.fna | wc -l)
if [[ "${N_GENOMES}" -eq 0 ]]; then
  echo "No genomes (*.fna) found in input dir"
  exit 1
fi

if [[ ! -a "${HMM_FILE}" ]]; then
  echo "Missing hmm file"
  echo "Use \"--hmm_file\" to set the hmm to annotate"
  exit 1
fi  

if [[ ! -a "${CONFIG_FILE}" ]]; then
  CONFIG_FILE="$(dirname $(readlink -f $0))/conf.sh"
  if [[ -a "${CONFIG_FILE}" ]]; then
  
    source "${CONFIG_FILE}"
    
    if [[ $? -ne 0 ]]; then
      echo "Source config file failed"
      exit 
    fi  
    
  else  
    echo "Missing configuration file"
    echo "Use \"--config_file\" to set confiuration file"
    exit 1
  fi  
else   
  source "${CONFIG_FILE}"
fi  

###############################################################################
# 5. Set dfaults
###############################################################################

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="ref_cds_labelled"
fi

if [[ "${VERBOSE}" == "t" ]]; then
  function handleoutput {
    cat /dev/stdin | \
    while read STDIN; do
      echo "${STDIN}"
    done
  }
else
  function handleoutput {
  cat /dev/stdin >/dev/null
}
fi

export -f handleoutput

if [[ -z "${FILTER_BY_EVALUE}" ]]; then
  FILTER_BY_EVALUE="f"
fi  

if [[ -z "${FILTER_BY_GA}" ]]; then
  FILTER_BY_GA="f"
fi  

if [[ -z "${FILTERING_EVALUE}" ]]; then
  FILTERING_EVALUE="0.1"
fi  

if [[ -z "${OVERWRITE}" ]]; then
  OVERWRITE="f"
fi  

if [[ -z "${MIN_LENGTH}" ]]; then
  MIN_LENGTH="60"
fi  

if [[ -z "${MAX_EVALUE}" ]]; then
  MAX_EVALUE="1"
fi

if [[ -z "${SUBSAMPLE_N}" ]]; then
  SUBSAMPLE_N="1"
fi

if [[ -z "${CLEAN}" ]]; then
  CLEAN="1"
fi

if [[ -z "${NSLOTS}" ]]; then
  NSLOTS="4"
fi

if [[ -z "${SLIDE_WINDOW}" ]]; then
  SLIDE_WINDOW="30"
fi

if [[ -z "${ERROR_RATE}" ]]; then
  ERROR_RATE="1e-3"
fi

if [[ -z "${QUERY_FIELD}" ]]; then
  QUERY_FIELD="accession"
fi

if [[ -z "${READ_LENGTH}" ]]; then
  READ_LENGTH="100,200,300"
fi

###############################################################################
# 6. Creat output dir
###############################################################################

if [[ -d "${OUTPUT_DIR}" ]]; then
  if [[ "${OVERWRITE}" == "t" ]]; then
    rm -r "${OUTPUT_DIR}"
    mkdir "${OUTPUT_DIR}"
  else
    echo "${OUTPUT_DIR} already exists"
    exit 1
  fi    
else 
  mkdir "${OUTPUT_DIR}"
fi  

###############################################################################
# 7. Creat logs dir
###############################################################################

LOGS="${OUTPUT_DIR}/logs"

if [[ ! -d "${LOGS}" ]]; then
  mkdir "${LOGS}"
  
  if [[ $? -ne 0 ]]; then
    echo "mkdir ${LOGS} failed"
    exit 1
  fi    
  
fi

###############################################################################
# 8. Convert to aa
###############################################################################

echo "Converting input cds fna to faa ..." | handleoutput

mkdir "${OUTPUT_DIR}/aa_cds"
if [[ $? -ne 0 ]]; then
  echo "mkdir ${OUTPUT_DIR}/aa_cds failed"
  exit 1
fi

convert_to_aa() {

    NAME=$(basename "${1}" .fna)
    FAA_OUT="${OUTPUT_DIR}/aa_cds/${NAME}".faa
      
   "${transeq}" \
   -sformat pearson \
   -sequence "${1}" \
   -outseq "${FAA_OUT}" 2> /dev/null

   if [[ $? != "0" ]]; then
     echo "transeq failed ${LINE}"
     exit 1
   fi
}   

env_parallel \
-j "${NSLOTS}" \
"convert_to_aa {}" \
::: $(ls "${INPUT_DIR}/"*.fna)

if [[ $? -ne 0 ]]; then
  echo "convert to aa failed"
  exit 1
fi  

###############################################################################
# 9. Annotate domains
###############################################################################

echo "Annotating potential CDS ..." | handleoutput

INPUT_FILES=$(ls "${OUTPUT_DIR}/aa_cds"/*".faa")
mkdir -p "${OUTPUT_DIR}/annot_cds"

if [[ $? -ne "0" ]]; then
  echo "mkdir -p ${OUTPUT_DIR}/annot_cds failed"
fi

parallel \
-j "${NSLOTS}" \
"${hmmsearch} \
-E 30 \
--domE 30 \
--domtblout ${OUTPUT_DIR}/annot_cds/{/.}.domtblout \
--cpu 1 \
${HMM_FILE} {} > ${OUTPUT_DIR}/annot_cds/{/.}.hout" \
::: $(echo "${INPUT_FILES}")

if [[ $? -ne 0 ]]; then
  echo "hmmsearch failed"
  exit 1
fi  

###############################################################################
# 10. Extract potential domains (non overlapping seqs)
###############################################################################

echo "Extracting non overlapping domains ..." | handleoutput

mkdir -p "${OUTPUT_DIR}/extract_annot_seqs"
if [[ $? -ne "0" ]]; then
  echo "mkdir -p ${OUTPUT_DIR}/extract_annot_seqs"
fi

INPUT_FILES=$(ls "${OUTPUT_DIR}/annot_cds/"*".domtblout")

parallel \
-j "${NSLOTS}" \
"${MODULES}/extract_non_overlapping_seqs.sh \
--config_file ${CONFIG_FILE} \
--input_file {} \
--query_field ${QUERY_FIELD} \
--max_evalue "${MAX_EVALUE}" \
--genome_file ${INPUT_DIR}/{/.}.fna \
--output_dir ${OUTPUT_DIR}/extract_annot_seqs/{/.}_potential_domains \
--overwrite t | handleoutput" \
::: $(echo "${INPUT_FILES}") | tee "${LOGS}/extract_potential_seqs.logs"

if [[ $? -ne 0 ]]; then
  echo "extract_non_overlapping_seqs.sh failed"
  exit 1
fi  

###############################################################################
# 11. Extract negative_domains sequences (complete seqs)
###############################################################################

echo "Extracting negative domains ..." | handleoutput
INPUT_FILES=$(ls "${OUTPUT_DIR}/annot_cds/"*".domtblout")

parallel \
-j "${NSLOTS}" \
"${MODULES}/extract_complement_seqs.sh \
--config_file ${CONFIG_FILE} \
--input_file {} \
--genome_cds_file ${INPUT_DIR}/{/.}.fna \
--output_dir ${OUTPUT_DIR}/extract_annot_seqs/{/.}_negaitive_domains \
--overwrite t | handleoutput" \
::: $(echo "${INPUT_FILES}") | tee "${LOGS}/extract_complement_seqs.logs"

if [[ $? -ne 0 ]]; then
  echo "extract_complement_seqs.sh failed"
  exit 1
fi  

###############################################################################
# 12. Concatenate
###############################################################################

mkdir "${OUTPUT_DIR}/tagged_seqs"
if [[ $? -ne 0 ]]; then
  echo "mkdir ${OUTPUT_DIR}/tagged_seqs failed"
  exit 1
fi

cat "${OUTPUT_DIR}/extract_annot_seqs/"*"_potential_domains/potential_doms_non_overlapping.fna" > \
     "${OUTPUT_DIR}/tagged_seqs/01-potential_domains.fna"

if [[ $? -ne "0" ]]; then
  echo "Concatenate negative domains failed"
  exit 1
fi

cat "${OUTPUT_DIR}/extract_annot_seqs/"*"_negaitive_domains/negative_doms.fna" > \
     "${OUTPUT_DIR}/tagged_seqs/01-negative_domains.fna"

if [[ $? -ne "0" ]]; then
  echo "Concatenate potenital domains failed"
  exit 1
fi
  
###############################################################################
# 11. Filter by GA or evalue
###############################################################################

POTENTIAL_DOMAINS="${OUTPUT_DIR}/tagged_seqs/01-potential_domains.fna"

if [[ "${FILTER_BY_EVALUE}" == "t" ]]; then

  "${MODULES}/filter_by_evalue.sh" \
  --config_file "${CONFIG_FILE}" \
  --overwrite t \
  --filtering_evalue "${FILTERING_EVALUE}" \
  --input_file "${POTENTIAL_DOMAINS}" \
  --output_file "${OUTPUT_DIR}/tagged_seqs/01-potential_domains_filtered.fna"
  
  if [[ $? -ne "0" ]]; then
    echo "filter_by_evalue.sh failed"
    exit 1
  fi
  
  POTENTIAL_DOMAINS="${OUTPUT_DIR}/tagged_seqs/01-potential_domains_filtered.fna"

fi

if [[ "${FILTER_BY_GA}" == "t" ]]; then

  "${MODULES}/filter_by_ga.sh" \
  --config_file "${CONFIG_FILE}" \
  --overwrite t \
  --input_hmm "${HMM_FILE}" \
  --input_file "${POTENTIAL_DOMAINS}" \
  --output_file "${OUTPUT_DIR}/tagged_seqs/01-potential_domains_filtered.fna"
  
   if [[ $? -ne "0" ]]; then
     echo "filter_by_ga.sh failed"
     exit 1
   fi

  POTENTIAL_DOMAINS="${OUTPUT_DIR}/tagged_seqs/01-potential_domains_filtered.fna"

fi

###############################################################################
# 13. Extract short read sequences
###############################################################################

echo "Generating short read sequences ..." | handleoutput

mkdir "${OUTPUT_DIR}/tagsim"
if [[ $? -ne 0 ]]; then
  echo "mkdir ${OUTPUT_DIR}/tagsim failed"
  exit 1
fi

READ_LENGTH=${READ_LENGTH//\,/ }

parallel \
-j "${NSLOTS}" \
"${MODULES}/short_read_simulator.pl \
--input_file ${POTENTIAL_DOMAINS} \
--output_file ${OUTPUT_DIR}/tagsim/tagsim-potential_{}bp.fna \
--slide_window ${SLIDE_WINDOW} \
--error_rate "${ERROR_RATE}" \
--read_length {}" \
::: $(echo "${READ_LENGTH}")

if [[ $? -ne "0" ]]; then
  echo "Short read simulation of potenital domains failed"
  exit 1
fi

parallel \
-j "${NSLOTS}" \
"${MODULES}/short_read_simulator.pl \
--input_file ${OUTPUT_DIR}/tagged_seqs/01-negative_domains.fna \
--output_file ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp.fna \
--slide_window ${SLIDE_WINDOW} \
--error_rate "${ERROR_RATE}" \
--read_length {}" \
::: $(echo "${READ_LENGTH}")

if [[ $? -ne "0" ]]; then
  echo "Short read simulation of negative domains failed"
  exit 1
fi

###############################################################################
# 14. Subsample negative dataset
###############################################################################

if [[ "${SUBSAMPLE_N}" -ne 0 ]]; then
  
  subsample_fun() { 
  
    N_POTENTIAL=$(egrep -c ">" "${1}")
    N=$(echo "${N_POTENTIAL}*${SUBSAMPLE_N}" | bc)
    "${seqtk}" sample -s100 "${2}" "${N}"  
  }

  echo "Subsamplig negative domain short reads ..." | handleoutput
  
  export -f subsample_fun
  
  env_parallel \
  -j "${NSLOTS}" \
  "subsample_fun \
   ${OUTPUT_DIR}/tagsim/tagsim-potential_{}bp.fna \
   ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp.fna > \
   ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp_redu.fna" \
   ::: $(echo "${READ_LENGTH}")

  if [[ $? -ne "0" ]]; then
    echo "Subsample negative domains failed"
    exit 1
  fi  
  
fi

###############################################################################
# 15. Concat datasets
###############################################################################

parallel \
-j "${NSLOTS}" \
"cat ${OUTPUT_DIR}/tagsim/tagsim-potential_{}bp.fna \
     ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp_redu.fna > \
     ${OUTPUT_DIR}/tagsim/tagsim-{}bp.fna" \
::: $(echo "${READ_LENGTH}")     

if [[ $? -ne "0" ]]; then
  echo "concatenation failed"
  exit 1
fi  

###############################################################################
# 16. Clean
###############################################################################

parallel \
-j "${NSLOTS}" \
"rm ${OUTPUT_DIR}/tagsim/tagsim-potential_{}bp.fna \
    ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp.fna \
    ${OUTPUT_DIR}/tagsim/tagsim-negative_{}bp_redu.fna" \
::: $(echo "${READ_LENGTH}")     

if [[ "${CLEAN}" == "t" ]]; then

  echo "Cleaning ..." | handleoutput
  
  rm -r \
  "${OUTPUT_DIR}/aa_cds" \
  "${OUTPUT_DIR}/annot_cds" \
  "${OUTPUT_DIR}/extract_annot_seqs" \
  "${OUTPUT_DIR}/logs"

   if [[ $? -ne 0 ]]; then
     echo "Clean failed"
   fi  
fi

###############################################################################
# 17. Exit
###############################################################################

echo "tagsim.sh exited successfully"
exit 0
