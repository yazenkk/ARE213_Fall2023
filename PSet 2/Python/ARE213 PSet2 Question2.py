os.chdir("/Users/maxsnyder/Dropbox/Berkeley ARE/Year 2/First Semester/Applied Metrics/Metrics PS2")
import sys

import numpy as np
import pandas as pd
import statsmodels.api as sm

from sklearn.linear_model import LogisticRegression

#####################
# 2.b
#####################


#Set wd + import df
data = pd.read_csv("pset2.csv")

data['law'] = data['primary'] + (data['secondary']*2)
years = data.pivot(index = 'year', columns = ['state'], values = ['primary'])

#Save event time of the first year: 
secondary_time_pre = data.query('law ==2')
secondary_time = secondary_time_pre.loc[secondary_time_pre.groupby('state').year.idxmin()][['state', 'year']].rename(columns = {'year' : 'event_year'})

data_w_event_time = data.merge(secondary_time, on = 'state', how = 'left')
data_w_event_time['event_time'] = (data_w_event_time.year - data_w_event_time.event_year) - 1 

data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] > 5),5, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] < -4), 4, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where(np.isnan(data_w_event_time['event_time']), -1, data_w_event_time['event_time'])

df = pd.get_dummies(data_w_event_time, columns=['event_time'], prefix='INX').rename(columns=lambda x: x.replace('-', 'm')).drop(columns='INX_m1.0').set_index(['state', 'year'])
df['log_fatalities_per_capita'] = np.log(df['fatalities']  / df['population'])
df['fatalities_per_capita'] = (df['fatalities']  / df['population'])

#Drop north carolina, which only implemented secondary laws for one year

scalars = ['beer', 'college', 'totalvmt', 'precip', 'snow32', 'rural_speed', 'urban_speed']
factors = df.columns[df.columns.str.contains('INX')]
exog = factors.union(scalars)

import linearmodels as lm

#Borrowing from here: https://lost-stats.github.io/Model_Estimation/Research_Design/event_study.html

df_no_nc = df.query('state != "NC"')

mod = lm.PanelOLS(df_no_nc['log_fatalities_per_capita'], df_no_nc[exog], entity_effects=True, time_effects=True)
fit = mod.fit(cov_type='clustered', cluster_entity=True)
fit.summary

res = pd.concat([fit.params, fit.std_errors], axis = 1)
res['ci'] = res['std_error']*1.96

res = res.filter(like='INX', axis=0)
# Turn the coefficient names back to numbers
res.index = (
    res.index
        .str.replace('INX_', '')
        .str.replace('m', '-')
        .str.replace('.0', '')
        .astype('int')
        .rename('time_to_treat')
)

# And add our reference period back in, and sort automatically
res.reindex(range(res.index.min(), res.index.max()+1)).fillna(0)
res = res.sort_index()
# Plot the estimates as connected lines with error bars

ax = res.plot(
    y='parameter',
    yerr='ci',
    xlabel='Event Time',
    ylabel='Effect of Secondary Laws on Log Fatalities per Capita',
    legend=False
)

ax.axhline(0, linestyle='dashed')
ax.axvline(-1, linestyle='dashed')
fig = ax.get_figure()
fig.savefig("ps2_2b_output.pdf")


#####################
# 2.a
#####################


#Make event study for primary laws
primary_time_pre = data.query('law ==1')
primary_time = primary_time_pre.loc[primary_time_pre.groupby('state').year.idxmin()][['state', 'year']].rename(columns = {'year' : 'event_year'})

data_w_event_time = data.merge(primary_time, on = 'state', how = 'left')
data_w_event_time['event_time'] = (data_w_event_time.year - data_w_event_time.event_year) - 1 

#Consider dropping WA

data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] > 4),4, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] < -5), -5, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where(np.isnan(data_w_event_time['event_time']), -1, data_w_event_time['event_time'])

df = pd.get_dummies(data_w_event_time, columns=['event_time'], prefix='INX').rename(columns=lambda x: x.replace('-', 'm')).drop(columns='INX_m1.0').set_index(['state', 'year'])
df['log_fatalities_per_capita'] = np.log(df['fatalities']  / df['population'])
df['fatalities_per_capita'] = (df['fatalities']  / df['population'])


scalars = ['beer', 'college', 'totalvmt', 'precip', 'snow32', 'rural_speed', 'urban_speed']
factors = df.columns[df.columns.str.contains('INX')]
exog = factors.union(scalars)
mod = lm.PanelOLS(df['log_fatalities_per_capita'], df[exog], entity_effects=True, time_effects=True)
fit = mod.fit(cov_type='clustered', cluster_entity=True)
fit.summary

res = pd.concat([fit.params, fit.std_errors], axis = 1)
res['ci'] = res['std_error']*1.96

res = res.filter(like='INX', axis=0)
# Turn the coefficient names back to numbers
res.index = (
    res.index
        .str.replace('INX_', '')
        .str.replace('m', '-')
        .str.replace('.0', '')
        .astype('int')
        .rename('time_to_treat')
)

# And add our reference period back in, and sort automatically
res.reindex(range(res.index.min(), res.index.max()+1)).fillna(0)
res = res.sort_index()
# Plot the estimates as connected lines with error bars

ax = res.plot(
    y='parameter',
    yerr='ci',
    xlabel='Event Time',
    ylabel='Effect of Primary Laws on Log Fatalities per Capita',
    legend=False
)

ax.axhline(0, linestyle='dashed')
ax.axvline(-1, linestyle='dashed')
fig = ax.get_figure()
fig.savefig("ps2_2a_output_primary.pdf")


#####################
# 2.c
#####################

#Secondary laws
mod = lm.PanelOLS(df_no_nc['fatalities_per_capita'], df_no_nc[exog], entity_effects=True, time_effects=True)
fit = mod.fit(cov_type='clustered', cluster_entity=True)
fit.summary

res = pd.concat([fit.params, fit.std_errors], axis = 1)
res['ci'] = res['std_error']*1.96

res = res.filter(like='INX', axis=0)
# Turn the coefficient names back to numbers
res.index = (
    res.index
        .str.replace('INX_', '')
        .str.replace('m', '-')
        .str.replace('.0', '')
        .astype('int')
        .rename('time_to_treat')
)

# And add our reference period back in, and sort automatically
res.reindex(range(res.index.min(), res.index.max()+1)).fillna(0)
res = res.sort_index()
# Plot the estimates as connected lines with error bars

ax = res.plot(
    y='parameter',
    yerr='ci',
    xlabel='Event Time',
    ylabel='Effect of Secondary Laws on Fatalities per Capita',
    legend=False
)

ax.axhline(0, linestyle='dashed')
ax.axvline(-1, linestyle='dashed')
fig = ax.get_figure()
fig.savefig("ps2_2c_secondary_no_log_output.pdf")


#Primary laws

#Make event study for primary laws
primary_time_pre = data.query('law ==1')
primary_time = primary_time_pre.loc[primary_time_pre.groupby('state').year.idxmin()][['state', 'year']].rename(columns = {'year' : 'event_year'})

data_w_event_time = data.merge(primary_time, on = 'state', how = 'left')
data_w_event_time['event_time'] = (data_w_event_time.year - data_w_event_time.event_year) - 1 

#Consider dropping WA

data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] > 4),4, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where((data_w_event_time['event_time'] < -5), -5, data_w_event_time['event_time'])
data_w_event_time['event_time'] = np.where(np.isnan(data_w_event_time['event_time']), -1, data_w_event_time['event_time'])

df = pd.get_dummies(data_w_event_time, columns=['event_time'], prefix='INX').rename(columns=lambda x: x.replace('-', 'm')).drop(columns='INX_m1.0').set_index(['state', 'year'])
df['fatalities_per_capita'] = (df['fatalities']  / df['population'])


scalars = ['beer', 'college', 'totalvmt', 'precip', 'snow32', 'rural_speed', 'urban_speed']
factors = df.columns[df.columns.str.contains('INX')]
exog = factors.union(scalars)
mod = lm.PanelOLS(df['fatalities_per_capita'], df[exog], entity_effects=True, time_effects=True)
fit = mod.fit(cov_type='clustered', cluster_entity=True)
fit.summary

res = pd.concat([fit.params, fit.std_errors], axis = 1)
res['ci'] = res['std_error']*1.96

res = res.filter(like='INX', axis=0)
# Turn the coefficient names back to numbers
res.index = (
    res.index
        .str.replace('INX_', '')
        .str.replace('m', '-')
        .str.replace('.0', '')
        .astype('int')
        .rename('time_to_treat')
)

# And add our reference period back in, and sort automatically
res.reindex(range(res.index.min(), res.index.max()+1)).fillna(0)
res = res.sort_index()
# Plot the estimates as connected lines with error bars

ax = res.plot(
    y='parameter',
    yerr='ci',
    xlabel='Event Time',
    ylabel='Effect of Primary Laws on Fatalities per Capita',
    legend=False
)

ax.axhline(0, linestyle='dashed')
ax.axvline(-1, linestyle='dashed')
fig = ax.get_figure()
fig.savefig("ps2_2c_output_primary_no_log.pdf")





