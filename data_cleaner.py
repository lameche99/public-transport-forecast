import pandas as pd
from fredapi import Fred

def getCPIs(fred: Fred, start_date = None, end_date = None):
    cpi_urban = fred.get_series('CPIAUCSL',
                                observation_start=start_date,
                                observation_end=end_date)
    cpi_cars_new = fred.get_series('CUSR0000SETA01',
                                   observation_start=start_date,
                                   observation_end=end_date)
    cpi_cars_used = fred.get_series('CUSR0000SETA02',
                                    observation_start=start_date,
                                    observation_end=end_date,)
    cpis = pd.concat([cpi_urban, cpi_cars_new, cpi_cars_used], axis=1)
    cpis.index.name = 'datetime'
    cpis.columns = ['CPI', 'CPIcn', 'CPIcu']
    cpis.reset_index(inplace=True)
    monthly = cpis.groupby(
        pd.Grouper(key='datetime', freq='1M', label='left')
    ).agg(dict(zip(cpis.columns.tolist()[1:], ['mean'] * 3)))
    # cpis.dropna(axis=0, inplace=True)
    return monthly

def getMacros(fred: Fred, start_date = None, end_date = None):
    unrate = fred.get_series('UNRATE',
                             observation_start=start_date,
                             observation_end=end_date)
    wti = fred.get_series('DCOILWTICO',
                            observation_start=start_date,
                            observation_end=end_date)
    auto_rate = fred.get_series('RIFLPBCIANM72NM',
                                observation_start=start_date,
                                observation_end=end_date)
    auto_sales = fred.get_series('TOTALSA',
                                observation_start=start_date,
                                observation_end=end_date)
    disp_inc = fred.get_series('A229RX0',
                                observation_start=start_date,
                                observation_end=end_date)
    macros = pd.concat([unrate, wti, auto_rate, auto_sales, disp_inc], axis=1)
    macros.index.name = 'datetime'
    macros.columns = ['Unemployment', 'WTI', 'AutoRate', 'AutoSales', 'DispIncome']
    macros.reset_index(inplace=True)
    monthly = macros.groupby(
        pd.Grouper(key='datetime', freq='1M', label='left')
    ).agg(dict(zip(macros.columns.tolist()[1:], ['mean'] * 5)))
    # macros.dropna(axis=0, inplace=True)
    return monthly


def cleanNTD():
    pub_df = pd.read_excel('./monthly_ridership_2023.xlsx', sheet_name='UPT')
    useless = ['NTD ID', 'Legacy NTD ID', 'Reporter Type', 'UACE CD', 'Mode', 'TOS']
    clean_df = pub_df.loc[pub_df.Status == 'Active', ~pub_df.columns.isin(useless)]
    clean_df[['City', 'State']] = clean_df['UZA Name'].str.split(',', expand=True)
    clean_df.drop('UZA Name', inplace=True, axis=1)
    final_wide = clean_df.groupby(['State', '3 Mode']).sum().reset_index()
    final = final_wide.melt(id_vars=['State', '3 Mode'], value_vars=final_wide.columns.tolist()[2:])
    final.columns = ['State', 'Mode', 'datetime', 'UPT']
    final.set_index('datetime', inplace=True)
    final.index = pd.to_datetime(final.index).to_period('M').to_timestamp('M')
    return final