os.chdir("/Users/maxsnyder/Downloads/PSet3")
import sys
sys.stdout = open("PSet3_Q2_ARE213.log", 'w')


import numpy as np
import pandas as pd
import statsmodels.api as sm

import econtools.metrics as mt
from econtools import read, outreg, table_statrow, write_notes

from sklearn.linear_model import LogisticRegression

#####################
# 2
#####################

#Import all data
cities = pd.read_csv("pset3_cities.csv")
distances = pd.read_csv("pset3_distances.csv")
lines = pd.read_csv("pset3_lines.csv")
lines_dummy = pd.get_dummies(lines, prefix = "nlink", columns=['nlinks'] )
lines_dummy['nlinks'] = lines['nlinks']
 
stations = pd.read_csv("pset3_stations.csv")
cities_stations = pd.merge(stations, cities, on='cityid', how ='outer')
inner_lines_stations =  pd.merge(cities_stations, lines_dummy, on='lineid', how ='outer').fillna(0) 

group = inner_lines_stations.groupby(['cityid' ])["nlink_1", "nlink_2", "nlink_3", "nlink_4", "nlink_5", "nlink_6", "nlink_7", "nlink_8", "nlink_9", "nlink_18"].apply(lambda x : x.astype(int).sum())
group.index.name = 'cityid'
group.reset_index(inplace=True)

df_w_nlinks = pd.merge(cities, group, on = "cityid", how = "outer")

inner_lines_stations_open_before_2016 = inner_lines_stations.query('open ==1')

df_count_lines = inner_lines_stations_open_before_2016.groupby(['cityid'])['cityid'].count()
df_count_lines = pd.DataFrame(df_count_lines).rename(columns={"cityid": "count_of_lines"})
df_count_lines.index.name = 'cityid'
df_count_lines.reset_index(inplace=True)


df_w_nlinks_final = pd.merge(df_w_nlinks, df_count_lines, on = "cityid", how = "outer")
df_w_nlinks_final["count_of_lines"]=df_w_nlinks_final["count_of_lines"].fillna(0)

#2a: 

df = df_w_nlinks_final
y = 'empgrowth'
X = ['count_of_lines', 'nlink_1',  'nlink_2',  'nlink_3', 'nlink_4', 'nlink_5', 'nlink_6', 'nlink_7', 'nlink_8', 'nlink_9', 'nlink_18']
cluster_var = 'province_en'

results = mt.reg(
    df,                     # DataFrame
    y,                      # Dependent var (string)
    X,                      # Independent var(s) (string or list of strings)
    cluster=cluster_var,     # Cluster var (string)
    addcons=True
)

table_string = outreg(results)
print("2A Results")
print(results)

#2b:

shac_params = {
    'x': 'longitude',   # Column in `df`
    'y': 'latitude',    # Column in `df`
    'kern': 'unif',     # Kernel name
    'band': 2,          # Kernel bandwidth
}


results2 = mt.reg(
    df,                     # DataFrame
    y,                      # Dependent var (string)
    X,                      # Independent var(s) (string or list of strings)
    shac=shac_params,
    addcons=True
)

print("2B Results")
print(results2)
table_string2 = outreg(results2)


#2c. 
#Create residuals for both

df = df_w_nlinks_final.dropna(subset= ['empgrowth']).reset_index()
y = 'empgrowth'
X = ['nlink_1',  'nlink_2',  'nlink_3', 'nlink_4', 'nlink_5', 'nlink_6', 'nlink_7', 'nlink_8', 'nlink_9', 'nlink_18']

results2 = mt.reg(
    df,                     # DataFrame
    y,                      # Dependent var (string)
    X,                      # Independent var(s) (string or list of strings)
    addcons=True
)

df['y_residual'] = results2.resid

y = 'count_of_lines'
results_lines = mt.reg(
    df,                     # DataFrame
    y,                      # Dependent var (string)
    X,                      # Independent var(s) (string or list of strings)
    addcons=True
)

df['delta_lines_residual'] = results_lines.resid

df_w_line_id = pd.merge(df, stations, on='cityid', how ='inner')

#before residualize, emp growth on big qi, before that drop if employment growth or delta liens is missing
df_w_line_id["Sik"] = 1


line_residuals = df_w_line_id.groupby(['lineid'])["y_residual", "delta_lines_residual"].apply(lambda x : x.mean())
line_residuals.reset_index(inplace=True)

#Line residuals is missing one observation.
line_residuals_w_dummies = pd.merge(line_residuals, lines_dummy, on='lineid', how ='inner')

sum = df_w_line_id.groupby(['lineid'])["Sik", "count_of_lines"].apply(lambda x : x.sum())
sum.reset_index(inplace=True)
sum['Sik_final'] = sum['Sik'] / 513


line_residuals_w_dummies_with_sk = pd.merge(line_residuals_w_dummies, sum, on = "lineid", how = "inner")


df = line_residuals_w_dummies_with_sk
y = 'y_residual'
X = ['delta_lines_residual']
Z = ['open']
w = ['nlink_1',  'nlink_2',  'nlink_3', 'nlink_4', 'nlink_5', 'nlink_6', 'nlink_7', 'nlink_8', 'nlink_9', 'nlink_18']
weights_var = 'Sik_final'


ivresults = mt.ivreg(df = df, y_name = y, x_name = X, z_name = Z, w_name = w,
                        awt_name = 'Sik_final', addcons=True, vce_type = 'hc3')

table_string2 = outreg(ivresults, digits = 3)
print("2C Results")
print(ivresults)

sys.stdout.close()











