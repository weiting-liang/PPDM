import os
def filter_lines(file_path):
    filtered_lines = []
    with open(file_path, 'r') as file:
        header = file.readline()  # 读取表头
        for line in file:
            columns = line.strip().split('\t')
            if int(columns[4]) >= 2:
                filtered_lines.append(columns)
    return filtered_lines
def process_lines(filtered_lines):
    processed_lines = []
    for columns in filtered_lines:
        gene_id = columns[0]
        if columns[1] != '-':
            classes = columns[1].split('+')
        elif columns[3] != '-':
            classes = columns[3].split('+')
        else:
            continue
        for cls in classes:
            cls = cls.split('(')[0]
            processed_lines.append((gene_id, cls))
    return processed_lines
def save_to_tmp_profile(processed_lines, output_file):
    with open(output_file, 'w') as file:
        file.write(f'CDS_ID\tclass\n')
        for gene_id, cls in processed_lines:
            file.write(f'{gene_id}\t{cls}\n')
def main():
    input_file = 'finished.txt'
    output_dir = 'CDS_profile'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    with open(input_file, 'r') as file:
        for i, line in enumerate(file):
            file_path = line.strip()
            filtered_lines = filter_lines(file_path)
            processed_lines = process_lines(filtered_lines)
            output_file = os.path.join(output_dir, f'profile_{i}.txt')
            save_to_tmp_profile(processed_lines, output_file)
if __name__ == '__main__':
    main()

