# Press COMMAND + ENTER to run a single line in the console
print('Welcome to Rodeo!')

# Press CTRL + ENTER with text selected to run multiple lines
# For example, select the following lines
x = 7
x**2
# and remember to press CTRL + ENTER

# Here is an example of using Rodeo:

# Install packages

! pip install pandas
! pip install numpy
! pip install sklearn

# Import packages
import numpy as np
import pandas as pd
import statsmodels.api as sm

from sklearn.linear_model import LogisticRegression

os.chdir("/Users/maxsnyder/Dropbox/Berkeley ARE/Year 2/First Semester/Applied Metrics/Metrics PS1/ARE213_Fall2023")
df = pd.read_csv("PSet_1_ARE213/clean_pset1.csv")
df

################
#5.a
################

#Logit to estimate propensity score
y_log_reg = df['tobacco']

#cor with y and D
x1 = ['alcohol', 'mrace3_2', 'mrace3_3', 'ormothhis', 'adequacy', 'cardiac', 'pre4000', 'phyper', 'chyper', 
     'diabetes', 'anemia', 'lung', 'wgain', 'dmeduc', 'dgestat', 'dmage', 'dmar']

#cor with y not D
x3 = ['csex', 'totord9', 'isllb10', 'dlivord', 'dplural']


X_log_reg = df[x1+x3]

model = LogisticRegression(solver='liblinear', random_state=0)
model.fit(X_log_reg, y_log_reg)

#2nd column gives us predictions
predictions = model.predict_proba(X_log_reg)[:,1]

#Calculate weights
wt = (df['tobacco'] / predictions) + (1 - df['tobacco'] /1 -  predictions)

#Demeaned X matrix
demeaned_X = (X_log_reg - X_log_reg.mean())

#Loop through to create matrix associated with tau. Takes about five minutes to run.
for i in range(len(demeaned_X)):
    if(i == 0):
        y = pd.Series.to_frame(df['tobacco'][i] * demeaned_X.iloc[i])
    if(i > 0):
        x = pd.Series.to_frame(df['tobacco'][i] * demeaned_X.iloc[i])
        y = pd.concat([x, y], axis=1)
    #Progress bar    
    if(i % 5000 == 0):
        print(i)

#Sort d_times_demeaned_X to match other data
d_times_demeaned_X = pd.DataFrame.transpose(y).iloc[::-1]

#Outcome: birthweight
y_log_reg = df['dbrwt']

#Create final covariates matrix: 
double_robust_reg_X = pd.concat([df['tobacco'],
                                 X_log_reg,
                                 d_times_demeaned_X], axis=1)


fit_wls = sm.WLS(y_log_reg, double_robust_reg_X, weights=wt).fit()
print(fit_wls.summary())



################
#5.b
################

#https://www.kirenz.com/post/2019-08-12-python-lasso-regression-auto/

from sklearn.preprocessing import PolynomialFeatures

poly = PolynomialFeatures(degree=2)
X_poly = poly.fit_transform(X_log_reg)

from sklearn.model_selection import train_test_split

y_log_reg = df['dbrwt']

X_train, X_test, y_train, y_test = train_test_split(X_poly, y_log_reg, test_size=0.3, random_state=10)

reg = Lasso(alpha=.3, tol=1, normalize=True)
reg.fit(X_train, y_train)

#Drop coefs that are smaller then .001
keep_coef_after_lasso = pd.Series((reg.coef_ > .001))

X_poly_df = pd.DataFrame(X_poly)
x_a_tilde = (X_poly_df[X_poly_df.columns[keep_coef_after_lasso]])


#Repeat the same process for x_b_tilde

y_log_reg = df['tobacco']
X_train, X_test, y_train, y_test = train_test_split(X_poly, y_log_reg, test_size=0.3, random_state=10)

reg = Lasso(alpha=.0001, tol=1, normalize=True)
reg.fit(X_train, y_train)

print(reg.coef_)

keep_coef_after_lasso = pd.Series((reg.coef_ > .00001))

x_b_tilde = (X_poly_df[X_poly_df.columns[keep_coef_after_lasso]])


#Create final covar matrix with D and union of x_a_tilde and x_b_tilde

final_covars = pd.concat([ df['tobacco'], x_a_tilde, x_b_tilde], axis=1)

from sklearn.linear_model import LinearRegression

model = LinearRegression()
model.fit(final_covars, y_log_reg)

print(f"coefficients: {model.coef_}")
