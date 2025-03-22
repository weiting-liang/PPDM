#liangweiting
import csv
import json
import sys
import codecs
import pandas as pd

path = str(sys.argv[1])
jsonData = open(path + '.json', 'r', encoding='utf-8')
dic = json.load(jsonData)
keys = list(dic.keys())
GCFs_count = len(keys)
csv_df = pd.DataFrame(columns=('GCF', 'BGC'))
for i in keys:
        bgc_list = dic[i]
        bgc_count = len(dic[i])
        print(i, bgc_count)
        for j in bgc_list:
                csv_df = csv_df.append([{'GCF':i, 'BGC':j}], ignore_index=True)
csv_df.to_csv(path+'.csv')