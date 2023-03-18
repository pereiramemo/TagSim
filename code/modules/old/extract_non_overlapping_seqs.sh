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
--config_file CHAR              configuration file              
--input_file CHAR               hmmsearch output file (i.e., domtblout) to get sequences ids, coords, evalu and domains
--genome_file CHAR              genome cds fna file from whith sequences are extraced
--max_evalue NUM                maximum evalue of hits (default 1) 
--output_dir CHAR               directory to output generated data
--overwrite t|f                 overwrite directory (defaould f)
--query_field CHAR              field to parse hmmsearch output: accession or name (default accession)
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
  --genome_file)
  if [[ -n "${2}" ]]; then
    GENOME_FILE="${2}"
    shift
  fi
  ;;
  --genome_file=?*)
  GENOME_FILE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --genome_file=) # Handle the empty case
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
  --max_evalue)
  if [[ -n "${2}" ]]; then
    MAX_EVALUE="${2}"
    shift
  fi
  ;;
  --max_evalue=?*)
  MAX_EVALUE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --max_evalue=) # Handle the empty case
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

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="extracted_doms_output_dir"
fi

if [[ -z "${MAX_EVALUE}" ]]; then
  MAX_EVALUE="1"
fi

if [[ -z "${QUERY_FIELD}" ]]; then
  QUERY_FIELD="accession"
fi

###############################################################################
# 6. Check input and case
###############################################################################

if [[ ! -a "${INPUT_FILE}" ]]; then
  echo "Missing input file"
  echo "Use the \"--input_file\" flag to set the inpute (amino acid) fasta"
  exit 1
fi

if [[ ! -a "${GENOME_FILE}" ]]; then
  echo "No genome file"
  echo "Use the \"--genome_file\" flag to set the genome file"
  exit 1
fi  

###############################################################################
# 7. Create output directory and deifne output files
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

awk -v max_evalue="${MAX_EVALUE}" -v query_field="${QUERY_FIELD}" -v OFS="\t" '{

  if ($0 !~ "^#") {
  
    id=gensub("_1$","","g",$1)
    if (query_field == "accession") {
      hmm=$5
    }
    if (query_field == "name") {
      hmm=$4
    }
    evalue=$7
    i_evalue=$13
    score=$14
    ali_start_nuc=($18-1)*3
    ali_end_nuc=$19*3
    
    if (evalue <= max_evalue && i_evalue <= max_evalue) {
      print id, ali_start_nuc, ali_end_nuc, i_evalue, score, hmm
    }  
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
# 9. Filter overlapping regions
###############################################################################

"${MODULES}/overlapping_region_finder2.pl" \
"${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv" > \
"${OUTPUT_DIR}/tmp-02_overlapped_doms.tsv"

if [[ $? != "0" ]]; then
  echo "overlapping_region_finder2.pl failed"
  exit 1
fi

###############################################################################
# 10. Create bed file
###############################################################################

cat \
<(cut -f3- "${OUTPUT_DIR}/tmp-02_overlapped_doms.tsv" | sort | uniq) \
<(cat "${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv") | sort | uniq -u > \
"${OUTPUT_DIR}/tmp-03_non_overlapped_doms.tsv"

if [[ $? != "0" ]]; then
  echo "command to get non overlapping doms file failed"
  exit 1
fi

awk -v OFS="\t" '{print $1,$2,$3}' \
"${OUTPUT_DIR}/tmp-03_non_overlapped_doms.tsv" | \
sort | uniq > "${OUTPUT_DIR}/tmp-04_nuc.bed"

if [[ $? != "0" ]]; then
  echo "awk command to create bed file failed"
  exit 1
fi

###############################################################################
# 11. Index genomes
###############################################################################

if [[ -s "${GENOME_FILE}.fai" ]]; then
  rm "${GENOME_FILE}.fai"
fi  

"${samtools}" faidx "${GENOME_FILE}"

if [[ $? -ne "0" ]]; then
  echo "samtools faidx failed"
fi

###############################################################################
# 12. Extract sequences
###############################################################################

"${bedtools}" getfasta \
-fi "${GENOME_FILE}" \
-bed "${OUTPUT_DIR}/tmp-04_nuc.bed"  \
-fo "${OUTPUT_DIR}/tmp-05_seqs.fna"

if [[ $? != "0" ]]; then
  echo "bedtools failed"
  exit 1
fi

###############################################################################
# 13. Add meta data in header
###############################################################################

awk '{ 

  if (NR == FNR) {
  
    id2coords = gensub("lcl\\|","","g",$1)":"$2"-"$3
    eval = $4
    score = $5
    dom = $6
    
    array_id2count_ref[id2coords] = 1 + array_id2count_ref[id2coords]
    array_id2eval[id2coords][array_id2count_ref[id2coords]] = eval
    array_id2score[id2coords][array_id2count_ref[id2coords]] = score
    array_id2dom[id2coords][array_id2count_ref[id2coords]] = dom
    
    next
    
  }

  if ($0 ~ "^>") {
 
    id2coords = gensub(">lcl\\|","","g",$0)
    array_id2count_query[id2coords] = 1 + array_id2count_query[id2coords]
    
    eval = array_id2eval[id2coords][array_id2count_query[id2coords]] 
    score = array_id2score[id2coords][array_id2count_query[id2coords]]
    dom = array_id2dom[id2coords][array_id2count_query[id2coords]]
    
    print ">" id2coords "|" eval "|" score "|" dom 
    
  } else {
  
    print $0
    
  }  
}' "${OUTPUT_DIR}/tmp-03_non_overlapped_doms.tsv" \
   "${OUTPUT_DIR}/tmp-05_seqs.fna" > \
   "${OUTPUT_DIR}/potential_doms_non_overlapping.fna"
   
if [[ $? -ne 0 ]]; then
  echo "awk command to edit headers failed"
  exit 1
fi

###########################################################################
# 14. Check point 1: seq counts
###########################################################################

NSEQ_BED=$(wc -l < "${OUTPUT_DIR}/tmp-04_nuc.bed")
NSEQ_FASTA=$(egrep -c ">" "${OUTPUT_DIR}/potential_doms_non_overlapping.fna")

if [[ "${NSEQ_BED}" -ne "${NSEQ_FASTA}" ]]; then
  echo "Control of number of seqs failed"
  exit 1
fi

###########################################################################
# 15. Check point 2: headers
###########################################################################

MD5SUM_REF=$(sort "${OUTPUT_DIR}/tmp-03_non_overlapped_doms.tsv" |
             sed "s/lcl|//" | \
             "${md5sum}" | \
             awk '{print $1}')

MD5SUM_QUERY=$(egrep ">" "${OUTPUT_DIR}/potential_doms_non_overlapping.fna" | \
               awk -v FS="|" -v OFS="\t" '{
                 id_seq=gensub(">(.*):([0-9]+)-[0-9]+","\\1","g",$1)
                 coord_start=gensub(".*:([0-9]+)-[0-9]+","\\1","g",$1)
                 coord_end=gensub(".*:[0-9]+-([0-9]+)","\\1","g",$1)
                 eval=$2
                 score=$3
                 dom=$4
                 print id_seq,coord_start,coord_end,eval,score,dom
                 }' | \
              sort | \
              "${md5sum}" | \
              awk '{print $1}')

if [[ "${MD5SUM_REF}" != "${MD5SUM_QUERY}" ]]; then
  echo "Control of headers failed"
  exit 1
fi

###############################################################################
# 16. Check point 3: total sum of seqs
###############################################################################

NSEQ_TOTAL_REF=$(wc -l < "${OUTPUT_DIR}/tmp-01_seq2coords2eval2dom.tsv")
NSEQ_NON_OVERLAPPED=$(egrep -c ">" "${OUTPUT_DIR}/potential_doms_non_overlapping.fna")
NSEQ_OVERLAPPED=$(cut -f3- "${OUTPUT_DIR}/tmp-02_overlapped_doms.tsv" | \
               sort | uniq | wc -l)
NSEQ_TOTAL_QUERY=$(echo "${NSEQ_NON_OVERLAPPED} + ${NSEQ_OVERLAPPED}" | bc)

if [[ "${NSEQ_TOTAL_QUERY}" -ne  "${NSEQ_TOTAL_REF}" ]]; then
  echo "Control of sum of seqs failed"
  exit 1
fi

###########################################################################
# 17. Clean
###########################################################################

rm "${OUTPUT_DIR}"/tmp-*

if [[ $? -ne "0" ]]; then
  echo "Clean command failed"
  exit 1
fi  

###########################################################################
# 18. Exit
###########################################################################

echo -e "extract_non_overlapping_seqs.bash $(basename ${INPUT_FILE})\texited sucessfully"
exit 0


