mkdir -p contigs_profile
rm contigs_ko_profile.sh

#!/bin/bash

# file name
output_script="contigs_ko_profile.sh"

# read list
while IFS= read -r file; do
    # mag id
    base_name=`basename $file .emapper.annotations`
    # echo commond
    printf "%s\n" "sed '1d' $file | awk -v prefix=$base_name -F '\\t' '{print prefix \"\\t\" \$1 \"\\t\" \$12}' > ./contigs_profile/${base_name}.modified" >> $output_script
done < ./finished.annotations
