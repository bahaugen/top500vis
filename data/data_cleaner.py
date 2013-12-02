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
perf_data={}
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
        if len(variables[key])<42:
            print variables[key]
    
    print master_data
    master_data.to_csv('clean_data.csv')

    for index, row in master_data.iterrows():
        listid=row['ListID']
        if listid in perf_data.keys():
            perf_data[listid]['top']=max(perf_data[listid]['top'],row['RMax'])
            perf_data[listid]['bottom']=min(perf_data[listid]['bottom'],row['RMax'])
            perf_data[listid]['total']=perf_data[listid]['total']+row['RMax']
        else:
            perf_data[listid]={ 'top':row['RMax'],
                                'bottom':row['RMax'],
                                'total':row['RMax']}
    
    #perf_data_df=pd.DataFrame(columns=('listid','top','bottom','total'))
    perf_data_list=[]
    for key in lists:
        if key in perf_data:
            entry=perf_data[key]
            perf_data_list.append({'date':key,'top':entry['top'],'bottom':entry['bottom'],'total':entry['total']})
    perf_data_df=pd.DataFrame(perf_data_list)
    print perf_data_df
    perf_data_df.to_csv('perf_data.csv')


    core_data={}
    for index, row in master_data.iterrows():
        listid=row['ListID']
        if listid in core_data:
            core_data[listid]['max']=max(core_data[listid]['max'],row['Total Cores'])
            core_data[listid]['min']=min(core_data[listid]['min'],row['Total Cores'])
            core_data[listid]['mean']=core_data[listid]['mean']+row['Total Cores']
            if row['Rank']==1:
                core_data[listid]['#1']=row['Total Cores']

        else:
            if row['Rank']==1:
                core_data[listid]={'max':row['Total Cores'],
                                    'min':row['Total Cores'],
                                    'mean':row['Total Cores'],
                                    '#1':row['Total Cores']
                                    }
            else:
                core_data[listid]={ 'max':row['Total Cores'],
                                    'min':row['Total Cores'],
                                    'mean':row['Total Cores'],
                                    '#1':None
                                    }

    core_data_list=[]
    for key in lists:
        if key in core_data:
            entry=core_data[key]
            core_data_list.append({'date':key,'max':entry['max'],'min':entry['min'],'mean':entry['mean']/500.0,'#1':entry['#1']})
    core_data_df=pd.DataFrame(core_data_list)
    print core_data_df
    core_data_df.to_csv('core_data.csv')

    segment_data={}
    for index,row in master_data.iterrows():
        listid = row['ListID']
        segment=row['Segment']
        if listid in segment_data:
            if segment in segment_data[listid]:
                segment_data[listid][segment]+=1
            else:
                segment_data[listid][segment]=1
        else:
            segment_data[listid]={"date":listid,segment:1}
    print segment_data
    segment_list=[]
    for key in segment_data:
        segment_list.append(segment_data[key])
    segment_df=pd.DataFrame(segment_list)
    segment_df=segment_df.sort(columns="date")
    segment_df=segment_df.fillna(0)
    segment_df[['Government']] = segment_df[['Government']].astype(int)
    segment_df[['Others']] = segment_df[['Others']].astype(int)
    print segment_df
    segment_df.to_csv("segment_data.csv")

        
main()
