###############################################################################
### 1. Set env
###############################################################################

set -o pipefail 
source "${HOME}/workspace/dev/resfam/scripts/conf.bash"

###############################################################################
# 2. Define help
###############################################################################

show_usage(){
  cat <<EOF
Usage: ./hmmsearch_runner.bash <options>
--help                          print this help
--case CHAR                     potential_domains or negative_domains 
--hmm_file CHAR                 HMM file to annotate reference sequences
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
  --case)
  if [[ -n "${2}" ]]; then
    CASE="${2}"
    shift
  fi
  ;;
  --case=?*)
  CASE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --case=) # Handle the empty case
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
  NSLOTS="4"
fi  

if [[ -z "${OVERWRITE}" ]]; then
  OVERWRITE="f"
fi  

if [[ -z "${OUTPUT_DIR}" ]]; then
  OUTPUT_DIR="hmmsearch_output_dir"
fi

###############################################################################
# 5. Check input and case
###############################################################################

if [[ ! -a "${INPUT_FILE}" ]]; then
  echo "No input_file"
  echo "Use the \"--input_file\" flag to set the inpute (amino acid) fasta"
  exit 1
fi  

if [[ "${CASE}" != "potential_domains" && "${CASE}" != "negative_domains" ]]; then
  echo "Define \"--case\" as potential_domains or negative_domains"
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

if [[ "${OVERWRITE}" == "t" ]]; then
  if [[ -d "${OUTPUT_DIR}" ]]; then
    rm -r "${OUTPUT_DIR}"
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

DOMTBLOUT="${OUTPUT_DIR}/$(basename ${INPUT_FILE} | \
          sed "s/.faa\|.fasta|.fa/.domtblout/")"
OUTPUT_FILE="${OUTPUT_DIR}/$(basename ${INPUT_FILE} | \
             sed "s/.faa\|.fasta|.fa/.hmmout/")"




#!/bin/bash

set -o pipefail

###############################################################################
### 1. load environment
###############################################################################

WORKDIR="/bioinf/projects/megx/domain2class_predictions/synthetic_metagenomes/\
data_simulations/tgs_cds_simulations/"
source "${WORKDIR}/scripts/conf.bash"
source ~/.profile
module load bedtools

###############################################################################
### 2. get genome names, and dirs
###############################################################################

CASE="maybe"
GENOME_NAME=$(sed -n "${SGE_TASK_ID}"p "${REFCDSFNALIST}")
GENOME_NAME_SHORT=${GENOME_NAME/_cds_from_genomic.fna}
GENOME_FILE=$(ls "${OUTPUT_DIR}/ref_cds/${GENOME_NAME}")
CASE_DIR="${OUTPUT_DIR}/ref_cds_annot/${GENOME_NAME_SHORT}/${CASE}"

###############################################################################
### 3. reset counts.log
###############################################################################

if [[ -a "${CASE_DIR}/counts.log" ]]; then
  rm "${CASE_DIR}/counts.log"
fi

###############################################################################
### 4. Get Maybe Coords and seqs
###############################################################################

cat "${HMMLIST}" | \
while read LINE; do

  HMM_NAME="${LINE/.hmm/}"
  HMM_FILE="${CASE_DIR}/${GENOME_NAME_SHORT}"_cds_from_genomic_DOM_"${HMM_NAME}".hout

  if egrep -qw "^${HMM_NAME}" "${HMM_FILE}"; then

    # Get aa coordinates
    # Note1: coordinates are formatted be used with bedools: zero-base
    # Note2: the domain i-evalue is kept
    egrep  -w "^${HMM_NAME}" "${HMM_FILE}" | \
    awk -v OFS="\t" '{
    sub(/_1$/,"",$4);
    print $4,($18-1)*3,$19*3,$13}' > "${CASE_DIR}/tmp_${HMM_NAME}_seq2coords2eval.tsv"

    if [[ $? != "0" ]]; then
      echo "awk command to create aa.bed file failed ${HMM_NAME}"
      exit 1
    fi

    awk -v OFS="\t" '{print $1,$2,$3}' \
    "${CASE_DIR}/tmp_${HMM_NAME}_seq2coords2eval.tsv" > \
    "${CASE_DIR}/tmp_${HMM_NAME}_nuc.bed"

    if [[ $? != "0" ]]; then
      echo "awk command to create nuc.bed file failed ${HMM_NAME}"
      exit 1
    fi

    # Extract sequences
    "${fastafrombed}" \
    -fi "${GENOME_FILE}" \
    -bed "${CASE_DIR}/tmp_${HMM_NAME}_nuc.bed"  \
    -fo "${CASE_DIR}/tmp_${HMM_NAME}_seqs-01.fna"

    if [[ $? != "0" ]]; then
      echo "fastafrombed failed ${HMM_NAME}"
      exit 1
    fi

    # Add domain name in header
    sed -i "s/>\(.*$\)/>\1\|${HMM_NAME}/" "${CASE_DIR}/tmp_${HMM_NAME}_seqs-01.fna"

    if [[ $? != "0" ]]; then
      echo "sed command failed ${HMM_NAME}"
    fi

    # Add evalue to header
    awk '{

      if (NR == FNR) {
        id_ref = $1":"$2"-"$3
        a[id_ref] = $4
        next
      }
      if ($0 ~ />/) {

        sub(">","",$1)
        id_query=gensub(/(.*)\|.*/,"\\1","G",$0)
        dom=gensub(/.*\|(.*)/,"\\1","G",$0)
        
         if (a[id_query] == "") {
           print "error $id_query not found"
           exit 1 
         }
         print ">"id_query"|"dom"|"a[id_query]
       } else {
       print $0
      }

    }' "${CASE_DIR}/tmp_${HMM_NAME}_seq2coords2eval.tsv" \
       "${CASE_DIR}/tmp_${HMM_NAME}_seqs-01.fna" > \
       "${CASE_DIR}/tmp_${HMM_NAME}_seqs-02.fna"

    if [[ $? -ne "0" ]]; then
      echo "awk adding evalues failed"
      exit 1
    fi

    ###########################################################################
    # Control
    ###########################################################################

    NSEQ_BED=$(wc -l < "${CASE_DIR}/tmp_${HMM_NAME}_nuc.bed")
    NSEQ_FASTA_01=$(egrep -c ">" "${CASE_DIR}/tmp_${HMM_NAME}_seqs-01.fna")
    NSEQ_FASTA_02=$(egrep -c ">" "${CASE_DIR}/tmp_${HMM_NAME}_seqs-02.fna")

    # numbers 01
    if [[ "${NSEQ_BED}" -ne "${NSEQ_FASTA_01}" ]]; then
      echo "error bed and 01.fasta have diff number of seqs"
      exit 1
    fi

    # numbers 02
    if [[ "${NSEQ_BED}" -ne "${NSEQ_FASTA_02}" ]]; then
      echo "error bed and 02.fasta have diff number of seqs"
      exit 1
    fi

    # evalue assignement
    MD5SUM_REF=$(sort "${CASE_DIR}/tmp_${HMM_NAME}_seq2coords2eval.tsv" | md5sum | \
                 awk '{print $1}')
    MD5SUM_QUERY=$(egrep ">" "${CASE_DIR}/tmp_${HMM_NAME}_seqs-02.fna" | \
                   sed -e "s/>//" -e "s/[|]/\t/g" | cut -f1,3 | \
                   sed -e "s/:/\t/" -e "s/-/\t/" | sort | md5sum | \
                   awk '{print $1}')

    if [[ "${MD5SUM_REF}" != "${MD5SUM_QUERY}" ]]; then
      echo "error in evalue assignement"
      exit 1
    fi

  fi
  
  #############################################################################
  # Counts log
  #############################################################################

  if [[ -a "${CASE_DIR}/tmp_${HMM_NAME}_seqs-02.fna" ]]; then
    echo -e "${HMM_NAME}\t${NSEQ_FASTA_02}" >> "${CASE_DIR}/counts.log"
  else
    echo -e "${HMM_NAME}\t0" >> "${CASE_DIR}/counts.log"
  fi

done

###############################################################################
### 5. concatenate
###############################################################################

cat "${CASE_DIR}"/tmp_*_seqs-02.fna > "${CASE_DIR}/${GENOME_NAME_SHORT}_dom_seqs.fna"

if [[ $? -ne "0" ]]; then
  echo "concatenation failed"
  exit 1
fi

###############################################################################
### 6. clean
###############################################################################

rm "${CASE_DIR}"/tmp_*

if [[ $? != "0" ]]; then
  echo "clean"
  exit 1
fi
