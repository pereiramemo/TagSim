###############################################################################
#### 1. Set env
###############################################################################

source "${DEV}/resfam/scripts/conf.bash"

###############################################################################
#### 2. Download summary.txt 
###############################################################################

# download date 12/03/2021
wget -O "${WORK_DIR}/resources/tables/assembly_summary_refseq.txt" \
    "ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/assembly_summary_refseq.txt"

###############################################################################
#### 3. Parse assembly_summary_refeq.txt: select columns and complete genomes
###############################################################################

awk -v FS="\t" -v OFS="\t" '{

  if ($1 !~ "#") { 
    acc=$1
    tax_id=$6
    level=$12
    ftp_path=$20
    
    if (level == "Complete Genome") { 
      print acc,tax_id,level,ftp_path
    }  
    
  }
}' \
"${WORK_DIR}/resources/tables/assembly_summary_refseq.txt" > \
"${WORK_DIR}/resources/tables/assembly_summary_refseq_redu.txt"

###############################################################################
#### 4. Add taxa information
###############################################################################

Rscript \
"${WORK_DIR}/scripts/simulation_scripts/modules/taxid2taxa_path_mapper.R" \
"${WORK_DIR}/resources/tables/assembly_summary_refseq_redu.txt" \
30 \
30 \
"${WORK_DIR}/resources/tables/taxa_table_selected_genomes.tsv"

###############################################################################
#### 5. Create download path
###############################################################################

awk 'BEGIN {OFS="\t"; FS="\t" }; {
  if (NR > 1) {
    file = $11
    sub(".*/","",file)
    print $11"/"file"_cds_from_genomic.fna.gz";
  }
}' \
"${WORK_DIR}/resources/tables/taxa_table_selected_genomes.tsv" > \
"${WORK_DIR}/resources/tables/taxa_table_selected_genomes_paths.tsv"

###############################################################################
#### 6. Downlaod genomes
###############################################################################

wget \
--tries=3 \
--directory-prefix="${WORK_DIR}/simulations/ref_cds/" \
--timeout=120 \
-i "${WORK_DIR}/resources/tables/taxa_table_selected_genomes_paths.tsv"




