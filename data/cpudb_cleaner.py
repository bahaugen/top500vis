#This is a python script to work with the CPUDB dataset
#Blake Haugen

import pandas as pd
import os.path
import collections
import datetime as dt
processor_df=pd.read_csv("cpudb/processor.csv")
processor_df=processor_df[['date','clock','manufacturer_id','technology_id','model']]
print processor_df

manufacturer_df=pd.read_csv("cpudb/manufacturer.csv")
manufacturer_df=manufacturer_df[['name','manufacturer_id']]
print manufacturer_df

code_name_df=pd.read_csv("cpudb/code_name.csv")
#print code_name_df

microarchitecture_df=pd.read_csv("cpudb/microarchitecture.csv")
#print microarchitecture_df

processor_family_df=pd.read_csv("cpudb/processor_family.csv")
#print processor_family_df

technology_df=pd.read_csv("cpudb/technology.csv")
technology_df=technology_df[['technology','technology_id']]
#print technology_df

master_df=pd.merge(processor_df,manufacturer_df,on='manufacturer_id')
print master_df
#master_df=pd.merge(master_df,code_name_df,on='code_name_id')
#master_df=pd.merge(master_df,microarchitecture_df,on='microarchitecture_id')
#master_df=pd.merge(master_df,processor_family_df,on='processor_family_id')
#print master_df
master_df=pd.merge(master_df,technology_df,on='technology_id')
#master_df=pd.merge(master_df,tester,on='processor_id')
master_df=master_df[['date','clock','name','technology']]
print master_df
master_df=master_df.dropna(subset=['date','clock','name','technology'],how='any')
master_df=master_df.sort('date')
print master_df
master_df.to_csv("cpudb_freq.csv")
#print tester
