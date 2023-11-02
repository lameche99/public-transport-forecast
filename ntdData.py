import pandas as pd
import numpy as np


def cleanNTD(path: str):
    """
    This function reads the latest NTD monthly data on UPT per state,
    cleans it, and returns a dataframe in long format with a State,
    Mode of Transportation and total monthly UPT variables.
    :return: pd.Dataframe - clean NTD data
    """
    pub_df = pd.read_excel(f'{path}', sheet_name='UPT')
    useless = ['NTD ID', 'Legacy NTD ID', 'Reporter Type', 'UACE CD', 'Mode', 'TOS']
    clean_df = pub_df.loc[pub_df.Status == 'Active', ~pub_df.columns.isin(useless)]
    clean_df[['City', 'State']] = clean_df['UZA Name'].str.split(',', expand=True)
    clean_df.drop('UZA Name', inplace=True, axis=1)
    final_wide = clean_df.groupby(['State', '3 Mode']).sum().reset_index()
    final = final_wide.melt(id_vars=['State', '3 Mode'], value_vars=final_wide.columns.tolist()[2:])
    final.columns = ['State', 'Mode', 'datetime', 'UPT']
    final.set_index('datetime', inplace=True)
    final.index = pd.to_datetime(final.index).to_period('M').to_timestamp('M')
    final.reset_index(inplace=True)
    final = final.groupby(['State', 'Mode',
                           pd.Grouper(key='datetime', freq='1Y')]).sum().reset_index()
    final.set_index('datetime', inplace=True)
    return final