rm dRep.sh
while read line
do
    id=`echo $line | rev | cut -d '/' -f 2|rev`
    echo "dRep dereplicate dRep_output/$id -g $line*.fa -pa 0.9 -sa 0.99 -nc 0.3 --S_algorithm ANImf --genomeInfo all_checkm2_quality_report.modified3.rename.csv --completeness 50 --contamination 5 -p 12" >> dRep.sh
done < ./samples_bins.list
