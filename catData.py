import pandas as pd
import numpy as np

def getSeasons(dates: pd.DatetimeIndex):
    """
    This function creates a categorical variable for season.
    Winter: Dec, Jan, Feb; Spring: Mar, Apr, May; Summer: Jun, Jul, Aug
    Fall: Sep, Oct, Nov
    :param df: pd.DatetimeIndex - date time series
    :return: np.array - array of categorical values for each Season
    """
    mask_spr = (dates.month >= 3) & (dates.month <= 5)
    mask_fall = (dates.month >= 9) & (dates.month <= 11)
    mask_win = (dates.month == 12) | (dates.month <= 2)
    szns = np.where(mask_win, 'Winter',
                    np.where(mask_fall, 'Fall',
                            np.where(mask_spr, 'Spring', 'Summer')
                            )
                        )
    return szns


def getRegions(states: pd.Series):
    """
    This function returns an array of 6 US regions,
    the first 5 are the usual ones (NE, SE, W, MidW, SW),
    the 6th one is "Multi" and it refers to agencies that operate
    across multiple states.
    :param states: pd.Series - state codes for each observations
    """
    NORTHEAST = ['CT', 'DE', 'ME', 'MD', 'MA', 'NH', 'NJ', 'NY', 'PA', 'RI', 'VT']
    SOUTHEAST = ['AL', 'AR', 'FL', 'GA', 'KY', 'LA', 'MS', 'NC', 'SC', 'TN', 'VA', 'WV']
    MIDWEST = ['IL', 'IN', 'IA', 'KS', 'MI', 'MN', 'MO', 'NE', 'ND', 'OH', 'SD', 'WI']
    SOUTHWEST = ['AZ', 'NM', 'OK', 'TX']
    WEST = ['AK', 'CA', 'CO', 'HI', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY']
    mask_ne = (states.str in NORTHEAST)
    mask_se = (states.str in SOUTHEAST)
    mask_mw = (states.str in MIDWEST)
    mask_sw = (states.str in SOUTHWEST)
    mask_we = (states.str in WEST)
    regions = np.where(mask_ne, 'NE',
                       np.where(mask_se, 'SE',
                                np.where(mask_mw, 'MW',
                                         np.where(mask_sw, 'SW',
                                                  np.where(mask_we, 'W', 'Multi')))))
    return regions

def catVars(ntd: pd.DataFrame):
    """
    This function creates categorical variables:
    Season, Region, Safety
    """
    ntd['Season'] = getSeasons(ntd.index)
    ntd['Region'] = getRegions(ntd.State)