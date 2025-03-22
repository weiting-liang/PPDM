# read .tsv
with open('AMP_merge_results.tsv', 'r') as file:
    lines = file.readlines()
# write output
with open('AMP.faa', 'w') as output_file:
    for line in lines:
        columns = line.strip().split('\t')
        if len(columns) >= 2:
            output_file.write(f">{columns[0]}\n")
            output_file.write(f"{columns[1]}\n")
