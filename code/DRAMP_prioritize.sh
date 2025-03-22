#!/bin/bash
# input
input_file="outfmt6_results.filter.tsv"
# merge and sort
sort -k1,1 -k12,12nr -k11,11g -k3,3nr -k13,13nr "$input_file" > sorted_by_criteria.tsv
# choose best one
awk 'NR==1 {print; next} !seen[$1]++' sorted_by_criteria.tsv > final_results.tsv
# output
echo "结果已保存到 final_results.tsv"
