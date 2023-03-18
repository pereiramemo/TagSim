###############################################################################
### 1. Set env
###############################################################################

library(taxonomizr)
library(tidyverse)
args = commandArgs(trailingOnly=TRUE)

###############################################################################
### 2. Load list
###############################################################################

INPUT_FILE <- args[1]
N_PHYLA <- args[2] %>% as.numeric()
N_FAMILIES <- args[3] %>% as.numeric()
OUTPUT_TABLE <- args[4]

INPUT_FILE <- "/home/epereira/workspace/dev/resfam/resources/tables/assembly_summary_refseq_redu.txt"
N_PHYLA <- 30
N_FAMILIES <- 30

print(c("Input file", INPUT_FILE))
print(c("N phyla", N_PHYLA))
print(c("N families", N_FAMILIES))

INPUT_TABLE <- read_tsv(file = INPUT_FILE, col_names = F)
colnames(INPUT_TABLE) <- c("acc", "taxid", "level", "path")

###############################################################################
### 3. Map taxa path
###############################################################################

TAXA_TABLE <- getTaxonomy(ids = INPUT_TABLE$taxid, 
                          sqlFile = "/home/bioinf/resources/ncbi_taxonomy/accessionTaxa.sql") %>%
              as.data.frame()

TAXA_TABLE$tax_id <- INPUT_TABLE$taxid
TAXA_TABLE$acc <- INPUT_TABLE$acc
TAXA_TABLE$path <- INPUT_TABLE$path

###############################################################################
### 4. Clean TAXA_TABLE: Remove viruses, Eukaryota, and phyla and family NAs
###############################################################################

TAXA_TABLE_redu <- TAXA_TABLE %>%
                   filter(superkingdom != "Eukaryota", 
                          superkingdom != "Viruses",
                          !is.na(phylum),
                          !is.na(family)) %>%
                   droplevels

###############################################################################
### 5. Select Phyla
###############################################################################

phylum_unique  <- TAXA_TABLE_redu %>% 
                  .$phylum %>% 
                  unique()

set.seed(123)
phylum_unique_sampled <- sample(phylum_unique, N_PHYLA, replace = F)
  
TAXA_TABLE_redu_phyla <- TAXA_TABLE_redu %>%
                         filter(phylum %in% phylum_unique_sampled) %>%
                         droplevels()

###############################################################################
### 6. Select family
###############################################################################

family_unique_sampled <- character()

for (i in phylum_unique_sampled) {
  
  family_unique <- TAXA_TABLE_redu_phyla %>%
                   filter(phylum == i) %>%
                   .$family %>%
                    unique %>%
                    as.character()
  
  print(i)
  
  if (length(family_unique) <= N_FAMILIES) {
    
    family_unique_sampled <- c(family_unique, family_unique_sampled)
    
  } else {
    
    set.seed(123)
    x <- sample(x = family_unique, size = N_FAMILIES, replace = F)
    family_unique_sampled <- c(x, family_unique_sampled)
    
  }
}

TAXA_TABLE_redu_family <- TAXA_TABLE_redu_phyla %>%
                          filter(family %in% family_unique_sampled) 

###############################################################################
### 6. Select genomes
###############################################################################

TAXA_TABLE_redu_genomes <- TAXA_TABLE_redu_family %>%
                           group_by(superkingdom, phylum, class, order, family) %>%
                           summarize(i = sample(x = 1:length(path), size = 1, replace = F),
                                     genus = genus[i],
                                     species = species[i],
                                     tax_id = tax_id[i],
                                     acc = acc[i],
                                     path = path[i]) 

###############################################################################
### 7. Export output table
###############################################################################

write.table(x = TAXA_TABLE_redu_genomes, file = OUTPUT_TABLE, col.names = T, row.names = F, quote = F, sep = "\t")

