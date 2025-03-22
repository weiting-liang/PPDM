import csv
input_file = 'result_rgi_file.txt'
output_file = 'result_rgi_filter.txt'
with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
    reader = csv.reader(infile, delimiter='\t')
    writer = csv.writer(outfile, delimiter='\t')

    # Write the header to the output file
    header = next(reader)
    writer.writerow(header)

    for row in reader:
        # Check if the 10th column (index 9) is greater than 30
        # and the 19th column (index 18) has more than 50 characters
        if float(row[9]) > 30 and len(row[18]) > 50:
            writer.writerow(row)