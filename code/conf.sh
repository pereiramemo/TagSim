###############################################################################
## define general variables
###############################################################################
# dirs
BIOINF_BIN="/home/bioinf/bin/"
MODULES="/home/epereira/workspace/repositories/tagsim/code/modules"

# tools
transeq="/usr/bin/transeq"
hmmer_version="3.3"
hmmsearch="${BIOINF_BIN}/hmmer/hmmer-${hmmer_version}/bin/hmmsearch"
bedtools_version="2.30.0"
bedtools="${BIOINF_BIN}/bedtools/bedtools_v${bedtools_version}/bin/bedtools"
md5sum="/usr/bin/md5sum"
samtools_version="1.9"
samtools="${BIOINF_BIN}/samtools/samtools-${samtools_version}/samtools"
bbmap_version="38.79"
filterbyname="${BIOINF_BIN}/bbmap/bbmap-${bbmap_version}/filterbyname.sh"
bbduk="${BIOINF_BIN}/bbmap/bbmap-${bbmap_version}/bbduk.sh"
reformat="${BIOINF_BIN}/bbmap/bbmap-${bbmap_version}/reformat.sh"
seqtk="${BIOINF_BIN}/seqtk/seqtk"
uproc_version="1.2.0"
uproc_prot="${BIOINF_BIN}/uproc/uproc-${uproc_version}/uproc-prot"
uproc_makedb="${BIOINF_BIN}/uproc/uproc-${uproc_version}/uproc-makedb"
blast_version="2.10.0+"
segmasker="${BIOINF_BIN}/blast/blast_v${blast_version}/ncbi-blast-${blast_version}/bin/segmasker"

# parallel
source $(which env_parallel.bash)


