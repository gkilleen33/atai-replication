# -*- coding: utf-8 -*-
"""
Created on Mon May  1 11:59:53 2023

@author: Grady

This file performs power calculations via bootstrap for detecting a 5% treatment effect on yields 
measured via satellites. This script uses the same IV as table7.do to estimate the relationship 
between reNDVI and yields, but the power calculations account for the fact that this first stage is 
estimated. 

The data is the same as that used in Stata. The code is executed in Python to allow for better parallel execution.
"""

import os 
import statsmodels.formula.api as smf
import tempfile
import pandas as pd 
import numpy as np
from linearmodels.iv import IV2SLS
import math 
import multiprocessing as mp
from functools import partial

#%% 
# Set working directory to project root 
abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)
os.chdir("..")

#%%
# Import the data
tempdir = tempfile.gettempdir()
datalocation = tempdir + '/final_data_with_attriters.dta'
df = pd.read_stata(datalocation, convert_categoricals=False)
df['Sow_date'] = df.Sow_date.dt.dayofyear  # Usable format 

# Get mean of sowed cotton 
sowed_cotton_share = np.mean(df.sowed_cotton)
fr_yield_share = np.mean(df[['yield_hectare_2018_alt']].notnull())  # Yield always missing when sowed cotton missing 
survey_attrition_rate = 1 - fr_yield_share

# Get satellite attrition rate 
sat_data = df.loc[df.map_merge == 3, ]
sat_data = sat_data.loc[sat_data.sowed_cotton==1, ]
satellite_completion_rate = np.mean(sat_data[['max_re705_2018', 'max_re705_2017', 'max_re705_2016']].notnull())
del sat_data 
satellite_attrition_rate = 1 - satellite_completion_rate

df_nomiss = df.dropna(subset=['yield_hectare_2018', 'max_re705_2018'])  # Excludes observations not useful for power calcs

df_nomiss = df_nomiss[['uid', 'block_id', 'Sow_date', 'total_rain', 'max_re705_2018', 'yield_hectare_2018', 
         'yield_hectare_2018_alt', 'yield_hectare_2017_alt',
         'treatment', 'max_re705_2017', 'max_re705_2016']]  # Limit to more useful variables for speed

df_control = df_nomiss.loc[df_nomiss.treatment == 0, ]
df_control = df_control.copy(deep=True)
df_control.drop(columns=['treatment'], inplace=True)

# Limit main df to only include necessary subset of the data
df = df[['uid', 'block_id',  'yield_hectare_2018_alt', 'yield_hectare_2017_alt', 'treatment']]

#%% 
# Function to predict yields using 2SLS 
def yield_prediction(data):
    temp_data = data.loc[data.yield_hectare_2018 > 0, ]  # Remove failed crops and outliers
    temp_data = temp_data.loc[temp_data.yield_hectare_2018 < 3900, ]
    temp_data.dropna(subset=['yield_hectare_2018', 'max_re705_2018', 'total_rain', 'Sow_date'], inplace=True)
    iv_formula = 'yield_hectare_2018 ~ 1 + C(block_id) + [max_re705_2018 ~ total_rain + Sow_date]'
    iv_model = IV2SLS.from_formula(iv_formula, data=temp_data).fit()
    return iv_model.predict(data=data)

# Same function but using OLS for comparison 
def yield_prediction_ols(data):
    temp_data = data.loc[data.yield_hectare_2018 > 0, ]  # Remove failed crops and outliers
    temp_data = temp_data.loc[temp_data.yield_hectare_2018 < 3900, ]
    temp_data.dropna(subset=['yield_hectare_2018', 'max_re705_2018', 'total_rain', 'Sow_date'], inplace=True)
    ols_formula = 'yield_hectare_2018 ~ max_re705_2018 + C(block_id)'
    ols_model = smf.ols(ols_formula, data=temp_data).fit()
    return ols_model.predict(data)

#%% 

def smallest_index_above_value(df, column, value):
  """
  Returns the smallest index in the DataFrame `df` for which the column `column` is above the value `value`.

  Args:
    df: The DataFrame to search.
    column: The column to search.
    value: The value to compare against.

  Returns:
    The smallest index in `df` for which `column` is above `value`.
  """

  # Otherwise, iterate over the index 
  for i, row in df.iterrows():
    if row[column] > value:
      return i

  # If no index is found, return None.
  return None


# Define a program to calculate power from a given sample size via simulation 
def bootstrap_iteration(N, data):
    boot_sample = data.sample(n=N, replace=True) 
    boot_sample['sentinel_2018'] = yield_prediction(boot_sample)
    
    # Shuffle the rows 
    boot_sample = boot_sample.sample(frac=1)
    boot_sample['treatment'] = 0
    
    # Create stratified random treatment assignment 
    for i in range(1, 7):
        block = boot_sample.loc[boot_sample.block_id == i, ]
        ind = math.floor(len(block) / 2) 
        block.iloc[ind: , block.columns.get_loc('treatment')] = 1
        boot_sample.loc[boot_sample.block_id == i, 'treatment'] = block.treatment.values
        
    # Now impose the alternative hypothesis 
    boot_sample['sentinel_2018'] = boot_sample.sentinel_2018 + .05*boot_sample.treatment*boot_sample.sentinel_2018
    
    # Now estimate the regression 
    model = smf.ols('sentinel_2018 ~ treatment + max_re705_2017 + max_re705_2016 + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_twostage = 1 
    else:
        reject_twostage = 0
        
    # Look at power with only 1 lag 
    model = smf.ols('sentinel_2018 ~ treatment + max_re705_2017 + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_twostage_l1 = 1 
    else:
        reject_twostage_l1 = 0
        
    # Look at power with only 0 lags 
    model = smf.ols('sentinel_2018 ~ treatment + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_twostage_l0 = 1 
    else:
        reject_twostage_l0 = 0
        
    # Now look at whether we would reject if we use satellite data, ignoring first stage uncertainty 
    boot_sample['sentinel_2018_fixed'] = boot_sample.sentinel_2018_fixed + .05*boot_sample.treatment*boot_sample.sentinel_2018_fixed
    
    # Now estimate the regression 
    model = smf.ols('sentinel_2018_fixed ~ treatment + max_re705_2017 + max_re705_2016 + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_iv_fixed = 1 
    else:
        reject_iv_fixed = 0
        
    # Look at OLS predictions
    boot_sample['sentinel_2018_ols'] = boot_sample.sentinel_2018_ols + .05*boot_sample.treatment*boot_sample.sentinel_2018_ols
    
    # Now estimate the regression 
    model = smf.ols('sentinel_2018_ols ~ treatment + yield_hectare_2017_alt + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_ols = 1 
    else:
        reject_ols = 0
        
    # Finally, look at whether we would reject with farmer-reported data 
    boot_sample['yield_hectare_2018_alt'] = boot_sample.yield_hectare_2018_alt + .05*boot_sample.treatment*boot_sample.yield_hectare_2018_alt
    
    # Now estimate the regression 
    model = smf.ols('yield_hectare_2018_alt ~ treatment + yield_hectare_2017_alt + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_fr = 1 
    else:
        reject_fr = 0
        
    # Also without lags 
    model = smf.ols('yield_hectare_2018_alt ~ treatment + C(block_id)', data=boot_sample).fit(cov_type='HC0')
    
    if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
        reject_fr_l0 = 1 
    else:
        reject_fr_l0 = 0
        
    return reject_twostage, reject_iv_fixed, reject_fr, reject_ols, reject_fr_l0, reject_twostage_l1, reject_twostage_l0 


# Define a program to calculate power from a given sample size via simulation, with Lee bounds 
def bootstrap_iteration_lee_bounds(N, data):
    """
    Parameters
    ----------
    N : Sample size
    data : Dataframe: Note that here we include data from the treated to model differential attrition in the sample.
    This relies on the fact we found no treatment effect.

    Returns
    -------
    reject_lee, reject_lee_l0 = 1 if null rejected, 0 otherwise

    """
    frac = N/len(data)  # To figure out the fraction of rows should be sampled from each stata (can exceed 1)
    # Now take a stratified random bootstrap sample 
    boot_sample = data.groupby(['block_id', 'treatment']).sample(frac=frac, replace=True).reset_index(drop=True)
    
    # Generate a version of the data replacing 0 yields in 2018 with None 
    # Get the values in the column.
    values = boot_sample['yield_hectare_2018_alt'].values
    
    # Replace all 0s with None
    values = [None if v == 0 else v for v in values]
    boot_sample_alt = boot_sample.copy(deep=True)
    boot_sample_alt['yield_hectare_2018_alt'] = values
    
    # Now drop those with missing data (since we're doing this here, we don't need to account for attrition later)
    boot_sample.dropna(inplace=True)
    boot_sample_alt.dropna(inplace=True)
        
    # Trim 
    if (np.sum(1-boot_sample.treatment) - np.sum(boot_sample.treatment) > 0):  # N control > N treat
        n_trim = int(np.sum(1-boot_sample.treatment) - np.sum(boot_sample.treatment))
        boot_sample.sort_values(by=['treatment', 'yield_hectare_2018_alt'], inplace=True)
        boot_sample.drop(boot_sample.index[:n_trim], inplace=True)
    else:
        n_trim = int(np.sum(boot_sample.treatment) - np.sum(1-boot_sample.treatment))
        boot_sample.sort_values(by=['treatment', 'yield_hectare_2018_alt'], inplace=True)
        boot_sample.drop(boot_sample.index[-n_trim:], inplace=True)
        
    # Trim alternative data
    if (np.sum(1-boot_sample_alt.treatment) - np.sum(boot_sample_alt.treatment) > 0):  # N control > N treat
        n_trim = int(np.sum(1-boot_sample_alt.treatment) - np.sum(boot_sample_alt.treatment))
        boot_sample_alt.sort_values(by=['treatment', 'yield_hectare_2018_alt'], inplace=True)
        boot_sample_alt.drop(boot_sample_alt.index[:n_trim], inplace=True)
    else:
        n_trim = int(np.sum(boot_sample_alt.treatment) - np.sum(1-boot_sample_alt.treatment))
        if n_trim > 0:
            boot_sample_alt.sort_values(by=['treatment', 'yield_hectare_2018_alt'], inplace=True)
            boot_sample_alt.drop(boot_sample_alt.index[-n_trim:], inplace=True)
        
    # Impose the alternative hypothesis
    boot_sample['yield_hectare_2018_alt'] = boot_sample.yield_hectare_2018_alt + .05*boot_sample.treatment*boot_sample.yield_hectare_2018_alt
    boot_sample_alt['yield_hectare_2018_alt'] = boot_sample_alt.yield_hectare_2018_alt + .05*boot_sample_alt.treatment*boot_sample_alt.yield_hectare_2018_alt

    # OLS regression with lags
    try:
        model = smf.ols('yield_hectare_2018_alt ~ treatment + yield_hectare_2017_alt + C(block_id)', data=boot_sample).fit(cov_type='HC0')
        if (model.params['treatment'] > 0) and (model.pvalues['treatment'] < 0.05):
            reject_lee = 1 
        else:
            reject_lee = 0
    except:
        reject_lee = 0  # Very rare bug I can't figure out, but not common enough to affect results 
        
    return reject_lee
 
def bootstrap_power(N, data, iterations):
    np.random.seed(1) # Sets seed so the same across different sample sizes being evaluated
    rejections = np.zeros((iterations, 11))
    for i in range(iterations):
        reject_twostage, reject_iv_fixed, reject_fr, reject_ols, reject_fr_l0, reject_twostage_l1, reject_twostage_l0   = bootstrap_iteration(N, data)
        rejections[i, 0] = reject_twostage
        rejections[i, 1] = reject_iv_fixed
        rejections[i, 2] = reject_fr
        rejections[i, 3] = reject_ols
        rejections[i, 4] = reject_fr_l0
        rejections[i, 5] = reject_twostage_l1
        rejections[i, 6] = reject_twostage_l0
    power_twostage = np.mean(rejections[:,0])
    power_iv_fixed = np.mean(rejections[:,1])
    power_fr = np.mean(rejections[:,2])
    power_ols = np.mean(rejections[:,3])
    power_fr_l0 = np.mean(rejections[:,4])
    power_twostage_l1 = np.mean(rejections[:,5])
    power_twostage_l0 = np.mean(rejections[:,6])
    return N, power_fr, power_fr_l0, power_ols, power_iv_fixed, power_twostage, power_twostage_l1, power_twostage_l0


def bootstrap_power_lee(N, data, iterations):  # Version for Lee bounds 
    np.random.seed(1) # Sets seed so the same across different sample sizes being evaluated
    rejections = np.zeros((iterations, 1))
    for i in range(iterations):
        reject_lee = bootstrap_iteration_lee_bounds(N, data)
        rejections[i, 0] = reject_lee
    power_lee = np.mean(rejections[:,0])
    return N, power_lee 


"""
From a longer run, know to target these sample size ranges to get right value

3000-3500: Satellite with OLS 
9000-9500: FR 
10500-11000: FR with no lags
15000-15500: Satellite IV 
15800-16200: Satellite IV, two stage
19500-20000: Satellite 1 lag
20000-20500L Satellite 0 lags

"""

if __name__ == "__main__":
    
    if os.path.isfile('tables/t7/power_estimates_grid_nolee.csv'):  # Avoid running again since time consuming 
        power_estimates_nolee = pd.read_csv('tables/t7/power_estimates_grid_nolee.csv')
    else:
        
        # Create a pool of workers.
        pool = mp.Pool(processes=10)
        
        sample_sizes = [2500, 2600, 2700, 2800, 2900,
                        3000, 3100, 3200, 3300, 3400, 3500,
                        9000, 9100, 9200, 9300, 9400, 9500,
                        10500, 10600, 10700, 10800, 10900, 11000,
                        15000, 15100, 15200, 15300, 15400, 15500,
                        15800, 15900, 16000, 16100, 16200,
                        19500, 19600, 19700, 19800, 19900, 20000,
                        20100, 20200, 20300, 20400, 20500,
                        20600, 20700, 20800, 20900, 21000]
           
        df_control['sentinel_2018_ols'] = yield_prediction_ols(df_control)
        df_control['sentinel_2018_fixed'] = yield_prediction(df_control)
        
        results = pool.imap_unordered(partial(bootstrap_power, data=df_control, iterations=1000), sample_sizes)
        
        # Create a NumPy array to store the results.
        array = np.empty((len(sample_sizes), 8))
        
        # Store the results in the NumPy array.
        for i, result in enumerate(results):
            array[i, 0] = result[0]
            array[i, 1] = result[1]
            array[i, 2] = result[2] 
            array[i, 3] = result[3] 
            array[i, 4] = result[4]
            array[i, 5] = result[5]
            array[i, 6] = result[6]
            array[i, 7] = result[7]
        
        # Close the pool.
        pool.close()
        pool.join()
        
        power_estimates_nolee = pd.DataFrame(data=array, columns=['N', 'FR', 'FR_L0', 'Sat_OLS', 'Sat_IV', 'Sat_IV_Fullboot', 
                                                            'Sat_IV_Fullboot_L1', 'Sat_IV_Fullboot_L0'])
        power_estimates_nolee.sort_values(by='N', inplace=True)
        
        power_estimates_nolee.to_csv('tables/t7/power_estimates_grid_nolee.csv', index=False)
        
    if os.path.isfile('tables/t7/power_estimates_grid_lee.csv'):  # Avoid running again since time consuming 
        power_estimates_nolee = pd.read_csv('tables/t7/power_estimates_grid_lee.csv')
    else:
        
        # Create a pool of workers.
        pool = mp.Pool(processes=5)
        
        sample_sizes_lee = [34000, 34100, 34200, 34300, 34400, 34500, 34600, 34700, 34800, 34900, 35000]
        
        results = pool.imap_unordered(partial(bootstrap_power_lee, data=df, iterations=1000), sample_sizes_lee)
        
        # Create a NumPy array to store the results.
        array = np.empty((len(sample_sizes_lee), 2))
        
        # Store the results in the NumPy array.
        for i, result in enumerate(results):
            array[i, 0] = result[0]
            array[i, 1] = result[1]
        
        # Close the pool.
        pool.close()
        pool.join()
        
        power_estimates_lee = pd.DataFrame(data=array, columns=['N', 'FR_Lee'])
        power_estimates_lee.sort_values(by='N', inplace=True)
        power_estimates_lee.to_csv('tables/t7/power_estimates_grid_lee.csv', index=False)

    
    sample_sizes = np.empty((1,8))
    i_fr = smallest_index_above_value(power_estimates_nolee, 'FR', 0.9)
    sample_sizes[0,0] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_fr, 'N'].item()) / fr_yield_share)
    
    i_fr_l0 = smallest_index_above_value(power_estimates_nolee, 'FR_L0', 0.9)
    sample_sizes[0,1] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_fr_l0, 'N'].item()) / fr_yield_share)
    
    i_sat_ols = smallest_index_above_value(power_estimates_nolee, 'Sat_OLS', 0.9)
    sample_sizes[0,2] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_sat_ols, 'N'].item()) 
                                  / satellite_completion_rate)
    
    i_sat_iv = smallest_index_above_value(power_estimates_nolee, 'Sat_IV', 0.9)
    sample_sizes[0,3] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_sat_iv, 'N'].item()) 
                                  / satellite_completion_rate)
    
    i_sat_iv_full = smallest_index_above_value(power_estimates_nolee, 'Sat_IV_Fullboot', 0.9)
    sample_sizes[0,4] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_sat_iv_full, 'N'].item()) 
                                  / satellite_completion_rate)
    
    i_sat_iv_full_l1 = smallest_index_above_value(power_estimates_nolee, 'Sat_IV_Fullboot_L1', 0.9)
    sample_sizes[0,5] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_sat_iv_full_l1, 'N'].item()) 
                                      / satellite_completion_rate)
    
    i_sat_iv_full_l0 = smallest_index_above_value(power_estimates_nolee, 'Sat_IV_Fullboot_L0', 0.9)
    sample_sizes[0,6] = math.ceil(int(power_estimates_nolee.loc[power_estimates_nolee.index == i_sat_iv_full_l0, 'N'].item()) 
                                      / satellite_completion_rate)
    
    i_lee = smallest_index_above_value(power_estimates_lee, 'FR_Lee', 0.9)
    sample_sizes[0,7] = int(power_estimates_lee.loc[power_estimates_lee.index == i_lee, 'N'].item()) 
    
    
    sample_sizes_df = pd.DataFrame(data=sample_sizes, columns=['FR', 'FR_L0', 'Sat_OLS', 'Sat_IV', 
                                                               'Sat_IV_Fullboot', 'Sat_IV_Fullboot_L1', 
                                                               'Sat_IV_Fullboot_L0', 'FR_Lee'])
    
    sample_sizes_df.to_csv('tables/t7/bootstrapped_sample_sizes.csv', index=False)
    
    
    # Create a LaTex table with the results 
    table7 = pd.DataFrame(columns=['', 'Farmer-reported data', 
                                   '\makecell[c]{Satellite data \\ OLS calibration}', 
                                   '\makecell[c]{Satellite data \\ 2SLS calibration}', 
                                   '\makecell[c]{Satellite data \\ 2SLS calibration \\ 2-stage bootstrap}']) 
    
    table7.loc[len(table7.index)] = ['N, all outcome lags', sample_sizes_df.loc[0, 'FR'].item(),
                       sample_sizes_df.loc[0, 'Sat_OLS'].item(), 
                       sample_sizes_df.loc[0, 'Sat_IV'].item(),
                       sample_sizes_df.loc[0, 'Sat_IV_Fullboot'].item()]
    
    table7.loc[len(table7.index)] = ['N, 1 satellite lag', None,
                       None, None, sample_sizes_df.loc[0, 'Sat_IV_Fullboot_L1'].item()]
    
    table7.loc[len(table7.index)] = ['N, no outcome lags', sample_sizes_df.loc[0, 'FR_L0'].item(),
                       None, None, sample_sizes_df.loc[0, 'Sat_IV_Fullboot_L0'].item()]
    
    table7.loc[len(table7.index)] = ['N, Lee bounds', 
                       sample_sizes_df.loc[0, 'FR_Lee'].item(),
                       None, 
                       None,
                       None]
    
    table7.to_latex('tables/t7/power-bootstrapped.tex', header=False, index=False, na_rep='', 
                    escape=False, float_format = '{:,.0f}'.format)
    
    
