'''
Clean up tables to prep for merge_year_csvs.py
'''

import sys, os
import pandas as pd
import accessdb_to_csv


BASEPATH = r"C:\Users\shooper\proj\savagedb\db\exported_tables"
CODENAME_TXT = r'C:\Users\shooper\proj\savagedb\db\exported_tables\%s\codenames.csv'
#CODENAME_TXT % 2016 = r"C:\Users\shooper\proj\savagedb\db\original\exported_tables\2016\codenames.csv"
# Codes to replace in codenames.codeletter
CODELETTERS = {'G': 'N',
               'Z': 'G',
               'H': 'Y',
               'Y': 'R',
               'X': 'C',
               'E': 'E',
               'F': 'O'
               }
# Codenames to replace in codenames.codetype and nonbus columns
KEEP_CODENAMES = {'entry': 'nonbus',
                  'blue': 'NPS approved',
                  'W': 'Right of Way',
                  'bus': 'bus'
                  }
# Tables to add the year to so records that aren't unique across years don't get dropped when merged
ADD_YEAR_TO = ['row_max',
               'gmp',
               'greenstudy']
# Column names to replace in each table
REPLACE_COLUMNS = {'bustraffic': {'busid':      'bus_id',
                                  'bustype':    'bus_type',
                                  'dest':       'destination',
                                  'lodg_o_n_':  'n_lodge_ovrnt',
                                  'pass_':      'n_passengers',
                                  'wlchair_':   'n_wheelchair',
                                  'training':   'is_training',
                                  'datacollector': 'observer_name'},
                   'datadates':  {'xdate':      'obs_date',
                                  'boxopen':    'open_time',
                                  'boxclose':   'close_time'},
                   'employees':  {'eprimary':   'employee_id',
                                  'ename':      'employee_name'},
                   'greenstudy': {'tpcode':     'trip_purpose_code',
                                  'wgcode':     'work_group_code',
                                  'nid':        'nps_vehicle_id'},
                   'nonbus':     {'dest':       'destination',
                                  'people_':    'n_passengers',
                                  'redwhite':   'permitholder_code',
                                  'trip_purp':  'trip_purpose',
                                  'workgrp':    'work_group',
                                  'nid':        'id',
                                  'datacollector': 'observer_name',
                                  'blue': 'approved_type'
                                  }
                   }

# Since definitions in the codenames table change year to year, use these values to consistently replace codes with
#   actual names
BUS_TYPES = {'D': 'Denali Natural History Tour',
             'T': 'Tundra Wilderness Tour',
             'S': 'Shuttle',
             'I': 'Windows Into Wilderness',
             'C': 'Camper',
             'N': 'North Face/Camp Denali',
             'B': 'Denali Backcountry Lodge',
             'K': 'Kantishna Roadhouse',
             'E': 'Kantishna Experience',
             'O': 'Other',
             'X': 'Eielson Excursion',
             'M': 'McKinley Gold Camp'}
APPROVED_TYPES = {'R': 'Researcher',
                  'E': 'Education',
                  'J': 'Concessionaire',
                  'O': 'Other'
                  }
DESTINATIONS = {'E': 'Eielson',
                'K': 'Kantishna',
                'M': 'Primrose/Mile 17',
                'O': 'Toklat',
                'P': 'Polychrome',
                'S': 'Stony Overlook',
                'T': 'Teklanika',
                'W': 'Wonder Lake',
                'X': 'Other'
                }

# Look-up table for mapping output table names from codetypes
'''_OUTPUT_TBLS = {'dest': 'destination_codes',
               'bus': 'bus_codes',
               'entry': 'nonbus_codes',
               'blue': 'npsapproved_codes',
               'W': 'rightofway_codes'
                }'''
_OUTPUT_TBLS = {'dest': 'destination_codes',
                'bus': 'bus_codes'}

NONBUS_COLUMNS = {''}


def split_codenames(df, out_dir):
    ''' split codename table into groups and get rid of extra fields like subcode and codetype'''

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



def main(export_tables=False):

    '''out_dir = BASEPATH.replace('exported_tables', 'cleaned_tables')
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)#'''

    if export_tables:
        accessdb_to_csv.main(BASEPATH, search_dir=os.path.join(os.path.split(BASEPATH)[0], 'original'))

    # add cid column to pre-2000 tables and make cid 46 == 55 in tables with year <= 2001
    print '\nAdding "cid" column to pre-2000 tables...\n'
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
        #import pdb; pdb.set_trace()
        bustraffic.loc[bustraffic.bustype == 'W', 'bustype'] = 'I'
        bustraffic.to_csv(bustraffic_txt, index=False)

    # Update nonbus codenames
    print 'Replacing codenames for',
    years = range(1997, 2016)
    for yr in years:
        year = str(yr)
        print '...%s' % year,
        # Replace codes, codenames, and explnations in codenames table
        codename_txt = CODENAME_TXT % year
        codenames = pd.read_csv(codename_txt)
        codenames.codeletter = codenames.codeletter.apply(replace_code)
        join = pd.merge(codenames, codenames2016, how='left', on='cid', suffixes=['', '_2016'])
        codenames.codename = join.codename_2016
        codenames.explanation = join.explanation

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

        # split destination, delete unnecessary code types and columns, and make codetypes more understandable
        codenames.loc[codenames.explanation == 'North Face - Camp Denali'] = 'North Face/Camp Denali'
        split_codenames(codenames, this_dir)
        codenames = codenames.loc[codenames.codetype.isin(KEEP_CODENAMES)]
        for cn in KEEP_CODENAMES:
            codenames[codenames.codename == cn] = KEEP_CODENAMES[cn]
        #   delete codes with different codenames from 2016/17
        codenames_txt = os.path.join(this_dir, 'codenames.csv')
        codenames = pd.read_csv(codenames_txt)
        delete_codenames = ['Education', 'WINWIN', 'SHUTTLE', 'Other bus', 'CAMPER', 'Eielson VC', 'Fish Creek', 'Mile 17']
        delete_explanations = ['Denali natural history tour', 'Tundra wildlife tour']
        codenames = codenames.loc[~codenames.codename.isin(delete_codenames) &
                                  ~codenames.explanation.isin(delete_explanations)]
        codenames.to_csv(codenames_txt, index=False)

        nonbus_txt = os.path.join(this_dir, 'nonbus.csv')
        nonbus = pd.read_csv(nonbus_txt)
        for column in ['entrytype', 'ticket', 'redwhite', 'dest', 'xaccess', 'blue']:
            nonbus[column] = nonbus[column].apply(make_upper)
        # delete the datacollector2 and dataentry2 fields. These contain employee IDs from the employees table, but only
        #   for 2001. All other years are blank. It's a completely unnecessary field because the name is already stored.
        for field in ['dataentry1', 'datacollector1', 'datacollector2', 'dataentry2', 'ticket', 'xaccess']:
            if field in nonbus.columns:
                nonbus.drop(field, axis=1, inplace=True)
        nonbus.rename(columns=REPLACE_COLUMNS['nonbus'], inplace=True)
        nonbus.replace({'destination': DESTINATIONS}, inplace=True)
        nonbus.replace({'approved_type': APPROVED_TYPES}, inplace=True)


        bustraffic_txt = os.path.join(this_dir, 'bustraffic.csv')
        bustraffic = pd.read_csv(bustraffic_txt)
        for column in ['bustype', 'training', 'dest']:
            bustraffic[column] = bustraffic[column].apply(make_upper)
        for field in ['dataentry1', 'datacollector1', 'datacollector2', 'dataentry2']:
            if field in nonbus.columns:
                nonbus.drop(field, axis=1, inplace=True)
        bustraffic['training'] = ~bustraffic.training.isnull()
        bustraffic.rename(columns=REPLACE_COLUMNS['bustraffic'], inplace=True)
        # replace bustype codes with actual values
        bustraffic['bus_type_code'] = bustraffic.bus_type
        bustraffic.replace({'bus_type': BUS_TYPES}, inplace=True)
        bustraffic.replace({'destination': DESTINATIONS}, inplace=True)
        for field in ['dataentry1', 'datacollector1']:
            if field in bustraffic.columns:
                bustraffic.drop(field, axis=1, inplace=True)
        bustraffic.to_csv(bustraffic_txt, index=False)

        # fix employees table
        #   drop rows where ename is null
        employee_txt = os.path.join(this_dir, 'employees.csv')
        employees = pd.read_csv(employee_txt)
        employees.dropna(subset=['ename'], inplace=True)
        employees.loc[employees.ename.apply(lambda x: 'Matt Christiansen' in x), 'ename'] = 'Matt Christiansen' # gets rid of '\r'
        employees.rename(columns=REPLACE_COLUMNS['employees'], inplace=True)
        employees.to_csv(employee_txt, index=False)


        # fix greenstudy tables
        greenstudywg_txt = os.path.join(this_dir, 'greenstudywg.csv')
        if os.path.isfile(greenstudywg_txt):
            greenstudywg = pd.read_csv(greenstudywg_txt)
            greenstudywg = greenstudywg.loc[~greenstudywg.work_group.isin(['B&U', 'Ranger', 'Rangers', 'Roads', 'Support-Maintenance', 'Trails'])]
            greenstudywg.rename(columns=REPLACE_COLUMNS['greenstudy'], inplace=True)
            greenstudywg.to_csv(greenstudywg_txt, index=False)
            greenstudy_txt = os.path.join(this_dir, 'greenstudy.csv')
            greenstudy = pd.read_csv(greenstudy_txt)

            # add the nonbus ID to the gsid column for 2007 only because this was the only year where green study ID
            #   was stored in nonbus rather than the nonbus ID being stored in the greenstudy table
            if yr == 2007:
                #import pdb; pdb.set_trace()
                greenstudy_cols = greenstudy.columns
                nonbus['id'] = xrange(len(nonbus))
                greenstudy = pd.merge(greenstudy, nonbus, how='left', left_on='gsid', right_on='gsid')
                try:
                    greenstudy['nps_vehicle_id'] = greenstudy['id']
                except Exception as e:
                    print e
                    import pdb; pdb.set_trace()
                greenstudy = greenstudy[greenstudy_cols]

            greenstudy.rename(columns=REPLACE_COLUMNS['greenstudy'], inplace=True)
            greenstudy.to_csv(greenstudy_txt, index=False)
        nonbus.to_csv(nonbus_txt, index=False) # write table to disk here so I can add 'id' field if necessary

        # replace column names in datadates table
        datadates_txt = os.path.join(this_dir, 'datadates.csv')
        datadates = pd.read_csv(datadates_txt)
        datadates.rename(columns=REPLACE_COLUMNS['datadates'], inplace=True)
        datadates.to_csv(datadates_txt, index=False)

        # add year to tables that would otherwise produce duplicate rows when merged
        for table_name in ADD_YEAR_TO:
            txt = os.path.join(this_dir, '%s.csv' % table_name)
            if os.path.exists(txt):
                table = pd.read_csv(txt)
                table['year'] = int(year)
                table.to_csv(txt, index=False)


        # rename dtype tables
        for table in REPLACE_COLUMNS.keys():
            csv = os.path.join(os.path.join(BASEPATH, 'dtypes'), '%s.csv' % table)
            df = pd.read_csv(csv, index_col='field')
            df.rename(index=REPLACE_COLUMNS[table]).to_csv(csv)



if __name__ == '__main__':
    if len(sys.argv) > 1:
        args = sys.argv[1:]
    else:
        args = []
    sys.exit(main(*args))












