'''
Clean up tables to prep for merge_year_csvs.py
'''

import sys, os
import re
import fnmatch
import pandas as pd

import accessdb_to_csv


BASEPATH = r"C:\Users\shooper\proj\savagedb\db\exported_tables"
CODENAME_TXT = r'C:\Users\shooper\proj\savagedb\db\exported_tables\%s\codenames.csv'

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
REPLACE_COLUMNS = {'bustraffic': {'busid':      'bus_number',
                                  'bustype':    'bus_type',
                                  'dest':       'destination',
                                  'lodg_o_n_':  'n_lodge_ovrnt',
                                  'pass_':      'n_passengers',
                                  'wlchair_':   'n_wheelchair',
                                  'training':   'is_training',
                                  'datacollector': 'observer_name',
                                  'dataentry':  'entered_by'},
                   'datadates':  {'xdate':      'obs_date',
                                  'boxopen':    'open_time',
                                  'boxclose':   'close_time'},
                   'employees':  {'eprimary':   'employee_id',
                                  'ename':      'employee_name'},
                   'greenstudy': {'tpcode':     'trip_purpose',
                                  'wgcode':     'work_group',
                                  'nid':        'nps_vehicle_id'},
                   'greenstudywg': {'gid': 'id',
                                    'work_group_code': 'code',
                                    'work_group': 'name'
                                    },
                   'nonbus':     {'dest':       'destination',
                                  'people_':    'n_passengers',
                                  'redwhite':   'permitholder_code',
                                  'nid':        'id',
                                  'datacollector': 'observer_name',
                                  'blue':       'approved_type',
                                  'dataentry':  'entered_by'
                                  }
                   }
WORK_GROUPS = {'B&U':               'Maintenance-BU',
               'Maintenance-BnU':   'Maintenance-BU',
               'Ranger':            'VRP Rangers',
               'Rangers':           'VRP Rangers',
               'Roads':             'Maintenance-Roads',
               'Support-Maintenance': 'Maintenance-Support',
               'Trails':            'Maintenance-Trails'
               }
WORK_GROUP_CODES = {'A':  'ADM',
                    'C':  'CON',
                    'I':  'INT',
                    'BU': 'MBU',
                    'MR': 'MRD',
                    'MT': 'MTR',
                    'MS': 'MST',
                    'R':  'RES',
                    'P':  'PLN',
                    'G':  'VRP',
                    'S':  'SUP',
                    'O':  'OTH'
                    }
TRIP_PURPOSE = {'Special Projects (5yrs or less)': 'Special projects',
                'Orientation Trip':                 'Orientation trip',
                'Routine Work':                     'Routine work',
                'Other (note in comment)':          'Other'}

# Since definitions in the codenames table change year to year, use these values to consistently replace codes with
#   actual names
BUS_TYPES = {'D': 'Denali Natural History Tour',
             'T': 'Tundra Wilderness Tour',
             'S': 'Shuttle',
             'I': 'Windows Into Wilderness',
             'C': 'Camper',
             'N': 'Camp Denali/North Face Lodge',
             'B': 'Denali Backcountry Lodge',
             'K': 'Kantishna Roadhouse',
             'E': 'Kantishna Experience',
             'O': 'Other',
             'X': 'Eielson Excursion',
             'M': 'McKinley Gold Camp'}
APPROVED_TYPES = {'R': 'Researcher',
                  'B': 'Researcher', #there's one record where the code is B, but it's clearly a researcher
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
                'X': 'Other',
                '0': 'Toklat'# there's one employee vehicle record with comment "TOKLAT" but dest = 0
                }

# Look-up table for mapping output table names from codetypes
OUTPUT_CODE_TBLS = {'dest': 'destination_codes',
                    'bus': 'bus_codes',
                    'blue': 'nps_approved_codes'}

NONBUS_COLUMNS = {''}


def split_codenames(df, out_dir):
    ''' split codename table into groups and get rid of extra fields like subcode and codetype'''

    groupby = df.groupby('codetype')

    # For each codetype, create a new table and write
    for group in groupby.groups.keys():
        # Codetypes that are actually
        if group not in OUTPUT_CODE_TBLS:
            continue
        this_group = groupby.get_group(group).copy()
        this_group.drop(['codetype', 'subcode'], axis=1, inplace=True)
        this_group.to_csv(os.path.join(out_dir, '%s.csv' % OUTPUT_CODE_TBLS[group]), index=False)


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
        # Only replace the code with 2016 values if it exists in 2016
        codenames.loc[~join.codename_2016.isnull(), 'codename'] = join[~join.codeletter_2016.isnull()]
        codenames.loc[~join.codename_2016.isnull(), 'explanation'] = join[~join.explanation_2016.isnull()]
        codenames.to_csv(codename_txt, index=False)
        # Replace codes in the nonbus table
        nonbus_txt = codename_txt.replace('codenames.csv', 'nonbus.csv')
        nonbus = pd.read_csv(nonbus_txt)
        nonbus.entrytype = nonbus.entrytype.apply(replace_code)

        # Only in 2013, Tek campers was changed to T
        if yr == 2013:
            nonbus.loc[nonbus.entrytype == 'T', 'entrytype'] = 'V'
        nonbus.to_csv(nonbus_txt, index=False)

    # Make all codes consistently uppercase. SQL doesn't care but other programs might
    def make_upper(x):
        try:
            return x.upper()
        except:
            return x

    print '\n\nCleaning records for',
    years = [int(d) for d in os.listdir(BASEPATH) if re.match('\d{4}', d)]
    for yr in years:
        year = str(yr)
        print '...%s' % year,
        this_dir = os.path.join(BASEPATH, year)

        # split destination, delete unnecessary code types and columns, and make codetypes more understandable
        codenames = pd.read_csv(CODENAME_TXT % year)
        codenames.loc[codenames.explanation == 'North Face - Camp Denali', 'explanation'] = 'Camp Denali/North Face Lodge'
        codenames = codenames.loc[codenames.codetype.isin(KEEP_CODENAMES)]
        for cn in KEEP_CODENAMES:
            codenames[codenames.codename == cn] = KEEP_CODENAMES[cn]
        #   delete codes with different codenames from 2016/17
        delete_codenames = ['Education', 'WINWIN', 'SHUTTLE', 'Other bus', 'CAMPER', 'Eielson VC', 'Fish Creek', 'Mile 17']
        delete_explanations = ['Denali natural history tour', 'Tundra wildlife tour']
        codenames = codenames.loc[~codenames.codename.isin(delete_codenames) &
                                  ~codenames.explanation.isin(delete_explanations)]
        split_codenames(codenames, this_dir)

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
        nonbus.loc[~nonbus.destination.isin(DESTINATIONS), 'destination'] = 'Other'
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
        greenstudytp_txt = greenstudywg_txt.replace('wg', 'tp')
        if os.path.isfile(greenstudywg_txt):
            greenstudywg = pd.read_csv(greenstudywg_txt)
            greenstudywg.rename(columns=REPLACE_COLUMNS['greenstudy'], inplace=True)
            greenstudy_txt = os.path.join(this_dir, 'greenstudy.csv')
            greenstudy = pd.read_csv(greenstudy_txt)
            greenstudytp = pd.read_csv(greenstudytp_txt)
            greenstudywg.replace({'work_group': WORK_GROUPS, 'work_group_code': WORK_GROUP_CODES}, inplace=True)
            greenstudytp.replace({'trip_purpose': TRIP_PURPOSE}, inplace=True)

            # add the nonbus ID to the gsid column for 2007 only because this was the only year where green study ID
            #   was stored in nonbus rather than the nonbus ID being stored in the greenstudy table
            if yr == 2007:
                #import pdb; pdb.set_trace()
                greenstudy_cols = greenstudy.columns.tolist() + ['nps_vehicle_id']
                nonbus['id'] = xrange(len(nonbus))
                greenstudy = pd.merge(greenstudy, nonbus, how='left', left_on='gsid', right_on='gsid')

                try:
                    greenstudy['nps_vehicle_id'] = greenstudy['id']
                except Exception as e:
                    print e
                    import pdb; pdb.set_trace()
                greenstudy = greenstudy[greenstudy_cols]

            # Replace codes with descriptions
            wg_code_dict = {code: name for _, (code, name) in greenstudywg[['work_group_code', 'work_group']].iterrows()}
            tp_code_dict = {code: name for _, (code, name) in greenstudytp[['trip_code', 'trip_purpose']].iterrows()}
            greenstudy.wgcode = greenstudy.wgcode.map(wg_code_dict).fillna('Other')
            greenstudy.tpcode = greenstudy.tpcode.map(tp_code_dict).fillna('Other')

            greenstudy.rename(columns=REPLACE_COLUMNS['greenstudy'], inplace=True)

            # There are several duplicates in pretty much every year's greenstudy table. There are
            #  also ghost records that don't correspond to any record in the nonbus table
            greenstudy = greenstudy.loc[~greenstudy.duplicated('nps_vehicle_id') &
                                        greenstudy.nps_vehicle_id.isin(nonbus.id)]

            # Join work group and trip purpose to nonbus
            joined = pd.merge(nonbus, greenstudy, how='left', left_on='id', right_on='nps_vehicle_id')
            try:
                nonbus['work_group'] = joined.work_group
                nonbus['trip_purpose'] = joined.trip_purpose
            except:
                import pdb; pdb.set_trace()

            # 2013 and 2014, work group and trip purpose were (mostly) recorded in the nonbus table with the an ID from
            #  the greenstudy work group/trip purpose tables
            if 'workgrp' in nonbus.columns:
                wg_code_dict = {code: name for _, (code, name) in greenstudywg[['gid', 'work_group']].iterrows()}
                nonbus['work_group'] = nonbus.workgrp.map(wg_code_dict).fillna(nonbus.workgrp)
            if 'trip_purp' in nonbus.columns:
                tp_code_dict = {code: name for _, (code, name) in greenstudytp[['gtpid', 'trip_purpose']].iterrows()}
                nonbus['trip_purpose'] = nonbus.trip_purp.map(tp_code_dict).fillna(nonbus.trip_purp)

            greenstudywg.rename(columns=REPLACE_COLUMNS['greenstudywg'], inplace=True)
            greenstudywg.to_csv(greenstudywg_txt, index=False)

        nonbus.to_csv(nonbus_txt, index=False)

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












