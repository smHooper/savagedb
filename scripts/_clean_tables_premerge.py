'''
Clean up tables to prep for merge_year_csvs.py
'''

import sys, os
import pandas as pd


BASEPATH = r"C:\Users\shooper\proj\savagedb\db\original\exported_tables"
CODENAME_TXT = r'C:\Users\shooper\proj\savagedb\db\original\exported_tables\%s\codenames.csv'
#CODENAME_TXT % 2016 = r"C:\Users\shooper\proj\savagedb\db\original\exported_tables\2016\codenames.csv"
CODELETTERS = {'G': 'N',
               'Z': 'G',
               'H': 'Y',
               'Y': 'R',
               'X': 'C',
               'E': 'E'
               }
ADD_YEAR_TO = ['row_max',
               'gmp',
               'greenstudy']
REPLACE_COLUMNS = {'bustraffic': {'busid':      'bus_id',
                                  'bustype':    'bus_type',
                                  'dest':       'destination',
                                  'lodg_o_n_':  'n_lodge_ovrnt',
                                  'pass_':      'n_passengers',
                                  'wlchair_':   'n_wheelchair',
                                  'xdate':      'obs_date'},
                   'datadates':  {'xdate':      'obs_date'},
                   'employees':  {'eprimary':   'employee_id',
                                  'ename':      'employee_name'},
                   'greenstudy': {'tpcode':     'trip_purpose_code',
                                  'wgcode':     'work_group_code'},
                   'nonbus':     {'dest':       'destination',
                                  'people_':    'n_passengers',
                                  'redwhite':   'permitholder_code',
                                  'trip_purp':  'trip_purpose',
                                  'workgrp':    'work_group',
                                  'xdate':      'obs_date'}
                   }
''' 
codenames: -delete codename == education,
            -delete explanation == 'Denali natural history tour'
            -delete codename == WINWIN
            -delete codename == 'SHUTTLE'
            -delete exlpanation == 'Tundra wildlife tour'
            -delete codename == 'Other bus'
            -delete codename == 'CAMPER'
            -delete codename == 'Eielson VC'
            -delete codename == 'Fish Creek'
            -delete codename == 'Mile 17'
            -change explanation == 'North Face - Camp Denali' to 'North Face/Camp Denali'
employees: drop nans
            -change ename where ename.apply(lambda x: 'Matt Christiansen' in x) to 'Matt Christiansen'
greenstudywg: - delete work_group == "B&U"
              - delete work_group == "Ranger"
              - delete work_group == "Rangers"
              - delete work_group == "Roads"
              - delete work_group == "Support-Maintenance"
              - delete work_group == "Trails"
 
   
'''




def split_codenames(df, out_dir):
    ''' split codename table into groups and get rid of extra fields like subcode and codetype'''
    # Look-up table for mapping output table names from codetypes
    _OUTPUT_TBLS = {'dest': 'destination_codes',
                   'bus': 'bus_codes',
                   'entry': 'nonbus_codes',
                   'blue': 'bluepermit_codes',
                   'W': 'rightofway_codes'
                    }

    groupby = df.groupby('codetype')
    '''out_dir = r"C:\Users\shooper\proj\savagedb\db\original\exported_tables\delete"
    if not os.path.isdir(out_dir):
        os.mkdir(out_dir)#'''

    # For each codetype, create a new table and write
    for group in groupby.groups.keys():
        # Codetypes that are actually
        if group not in _OUTPUT_TBLS:
            continue
        this_group = groupby.get_group(group).copy()
        this_group.drop(['codetype', 'subcode'], axis=1, inplace=True)
        this_group.to_csv(os.path.join(out_dir, '%s.csv' % _OUTPUT_TBLS[group]), index=False)


def replace_code(x):
    try:
        if x.upper() in CODELETTERS:
            return CODELETTERS[x.upper()]
    except: # might be NaN
        return x
    else:
        return x.upper()



def main():

    # add cid column to pre-2000 tables and make cid 46 == 55 in tables with year <= 2001
    print 'Adding "cid" column to pre-2000 tables...\n'
    codenames2001 = pd.read_csv(CODENAME_TXT % 2001)
    for yr in range(1997, 2000):
        year = str(yr)
        this_path = CODENAME_TXT % year
        df = pd.read_csv(this_path)
        df.loc[:18, 'cid'] = codenames2001.loc[:18, 'cid']
        df.loc[ 19, 'cid'] = 55 # this should be codename MGC. In 2001 table, MGC has CID 46 which is the same as prophos in post-2001 tables
        df.loc[20:, 'cid'] = codenames2001.loc[20:len(df) - 2] #all but last cid because last one is 46, MGC
        df.to_csv(this_path, index=False)
    codenames2001.loc[codenames2001.cid == 46, 'cid'] = 46
    codenames2001.to_csv(CODENAME_TXT % 2001, index=False)

    # change buscode W to I
    print 'Changing "Windows into Wilderness" codeletter from "W" to "I" for 2013 and 2014...\n'
    codenames2016 = pd.read_csv(CODENAME_TXT % 2016)
    for yr in range(2013, 2015): # only 2 years where Windows into Wilderness == 'W'; 2015 changed to 'I'
        year = str(yr)
        codenames_txt = CODENAME_TXT % year
        codenames = pd.read_csv(codenames_txt)
        codenames.loc[codenames.codeletter == 'I'] = codenames2016.loc[codenames2016.codeletter == 'W']
        codenames2016.to_csv(codenames_txt, index=False)
        bustraffic_txt = codenames_txt.replace('codenames', 'bustraffic')
        bustraffic = pd.read_csv(bustraffic_txt)
        bustraffic[bustraffic.bustype == 'W'] = 'I'
        bustraffic.to_csv(bustraffic_txt, index=False)

    # Update nonbus codenames
    print 'Replacing codenames for',
    years = range(1997, 2016)
    for yr in years:
        year = str(yr)
        print '...%s' % year,
        # Replace codes, codenames, and explnations in codenames table
        codename_txt = CODENAME_TXT % 2016
        codenames = pd.read_csv(codename_txt)
        codenames.codeletter = codenames.codeletter.apply(replace_code)
        #import pdb; pdb.set_trace()
        join = pd.merge(codenames, codenames2016, how='left', on='cid', suffixes=['', '_2016'])
        codenames.codename = join.codename_2016
        codenames.explanation = join.explanation

        # for each codetype, make a new table
        split_codenames(codenames, os.path.dirname(codename_txt))

        # Replace codes in the nonbus table
        nonbus_txt = codename_txt.replace('codenames.csv', 'nonbus.csv')
        nonbus = pd.read_csv(nonbus_txt)
        nonbus.entrytype = nonbus.entrytype.apply(replace_code)
        nonbus.to_csv(nonbus_txt, index=False)


    # Make all codes consistently uppercase. SQL doesn't care but other programs might
    def make_upper(x):
        try:
            return x.upper()
        except:
            return x

    print '\n\nCleaning records for',
    for yr in range(1997, 2018):
        year = str(yr)
        print '...%s' % year,
        this_dir = os.path.join(BASEPATH, year)
        nonbus_txt = os.path.join(this_dir, 'nonbus.csv')
        nonbus = pd.read_csv(nonbus_txt)
        for column in ['entrytype', 'ticket', 'redwhite', 'dest', 'xaccess']:
            nonbus[column] = nonbus[column].apply(make_upper)
        nonbus.to_csv(nonbus_txt, index=False)

        bustraffic_txt = os.path.join(this_dir, 'bustraffic.csv')
        bustraffic = pd.read_csv(bustraffic_txt)
        for column in ['bustype', 'training', 'dest']:
            bustraffic[column] = bustraffic[column].apply(make_upper)
        bustraffic.to_csv(bustraffic_txt, index=False)#'''

        # for each codetype, make a new table
        codenames_txt = os.path.join(this_dir, 'codenames.csv')
        codenames = pd.read_csv(codenames_txt)
        split_codenames(codenames, this_dir)

        # add year to tables that would otherwise produce duplicate rows when merged
        for table_name in ADD_YEAR_TO:
            txt = os.path.join(this_dir, '%s.csv' % table_name)
            if os.path.exists(txt):
                table = pd.read_csv(txt)
                table['year'] = int(year)
                table.to_csv(txt, index=False)


if __name__ == '__main__':
    sys.exit(main())












