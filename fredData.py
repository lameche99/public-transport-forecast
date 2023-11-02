import pandas as pd
import numpy as np
from fredapi import Fred

def getCPIs(fred: Fred, start_date = None, end_date = None):
    """
    This function gets time series for the CPI for urban consumers,
    CPI for new and used cars, according to the range provided, otherwise
    it returns the entire history.
    :param fred: fredapi.Fred - Fred API object
    :param start_date: str - time range start, default None
    :param end_date: str - time range end, default None
    :return: pd.DataFrame - nx3 data frame, where n is monthly observations
    in the specified date range
    """
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
        pd.Grouper(key='datetime', freq='1Y', label='left')
    ).agg(dict(zip(cpis.columns.tolist()[1:], ['mean'] * 3)))
    return monthly

def getMacros(fred: Fred, start_date = None, end_date = None):
    """
    This function gets time series for a series of macroeconomic
    variables, according to the range provided, otherwise
    it returns the entire history.
    :param fred: fredapi.Fred - Fred API object
    :param start_date: str - time range start, default None
    :param end_date: str - time range end, default None
    :return: pd.DataFrame - nx3 data frame, where n is monthly observations
    in the specified date range
    """
    unrate = fred.get_series('UNRATE',
                             observation_start=start_date,
                             observation_end=end_date)
    wti = fred.get_series('DCOILWTICO',
                            observation_start=start_date,
                            observation_end=end_date)
    auto_sales = fred.get_series('TOTALSA',
                                observation_start=start_date,
                                observation_end=end_date)
    disp_inc = fred.get_series('A229RX0',
                                observation_start=start_date,
                                observation_end=end_date)
    macros = pd.concat([unrate, wti, auto_sales, disp_inc], axis=1)
    macros.index.name = 'datetime'
    macros.columns = ['Unemployment', 'WTI', 'AutoSales', 'DispIncome']
    macros.reset_index(inplace=True)
    monthly = macros.groupby(
        pd.Grouper(key='datetime', freq='1Y', label='left')
    ).agg(dict(zip(macros.columns.tolist()[1:], ['mean'] * 4)))
    return monthly