#prepare list of contigs files: scaffolds.fa.gz.list

#get mash distance
sh get_mash_distance_work.sh

#get cloest samples
Rscript get_mash_colest20.R