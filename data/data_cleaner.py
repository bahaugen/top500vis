#This is a python script that cleans and compiles the Top 500 data set
#Blake Haugen

import pandas as pd
import os.path
import collections

years=range(1993,2014,1)
years=map(str,years)
months = ["06","11"]
lists=[]
for year in years:
    for month in months:
        lists.append(year+month)
file_prefix="raw_data/TOP500_"
file_suffix=".csv"
master_data=pd.DataFrame() 

def main():
    master_data=pd.DataFrame() 
    variables=collections.defaultdict(list)
    for list_date in lists:
        file_name=file_prefix+list_date+file_suffix
        if os.path.isfile(file_name):
            df=pd.read_csv(file_name)
            df.rename(columns={'Rmax':'RMax',
                                'Rpeak':'RPeak',
                                'Processors':'Total Cores',
                                'Cores':'Total Cores',
                                'Accelerator Cores':
                                'Accelerator/Co-Processor Cores',
                                'Accelerator':'Accelerator/Co-Processor',
                                'Effeciency (%)':'Efficiency (%)'},
                        inplace=True)
            df['ListID']=list_date
            master_data=master_data.append(df)
            for col_name in df.columns:
                variables[col_name].append(list_date)
        else:
            print file_name, "does not exist"
    #print df[90:100]
    for key in variables:
        print len(variables[key]),key
        if len(variables[key])<41:
            print variables[key]
    
    print master_data
    master_data.to_csv('clean_data.csv')



main()
