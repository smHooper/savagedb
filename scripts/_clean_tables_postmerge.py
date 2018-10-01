

import sys, os, shutil
from glob import glob
import pandas as pd
from titlecase import titlecase

pd.options.mode.chained_assignment = None

TABLES_WITH_DATES = ['nonbus', 'bustraffic', 'datadates']

CODES = {'W': 'right_of_way',
         'B': 'nps_approved',
         'N': 'nps_vehicles',
         'O': 'photographers',
         'P': 'accessibility',
         'R': 'employee_vehicles',
         'G': 'nps_contractors',
         'V': 'tek_campers',
         'C': 'cyclists',
         'Y': 'subsistence',
         'T': 'turned_around',
         'L': 'road_lottery'}

CONSTANT_FIELDS = ['id', 'observer_name', 'datetime', 'n_passengers', 'comments', 'destination']

NONBUS_FIELDS = {'W': ['driver_name',
                       'permit_number',
                       'permit_holder'],
                 'B': ['driver_name',
                       'approved_type',
                       'n_nights'],
                 'N': ['driver_name',
                       'trip_purpose',
                       'work_division',
                       'work_group',
                       'n_nights'],
                 'O': ['driver_name',
                       'permit_number',
                       'n_nights'],
                 'P': ['driver_name'],
                 'R': ['driver_name',
                       'permit_number'],
                 'G': ['organization',
                       'trip_purpose',
                       'n_nights'],
                 'V': [],
                 'C': [],
                 'Y': ['driver_name'],
                 'T': [],
                 'L': ['permit_number']
                 }



# Names to replace misspelled right-of-way permit holders
ROW_NAMES = {'Lisa&Steve Neff': 'Linda/Steve Neff',
             'CD/NFL': 'Camp Denali/North Face Lodge',
             'DBL': 'Denali Backcountry Lodge',
             'Gene Dejarlais': 'Gene Desjarlais',
             'Rusty Lachalt': 'Rusty Lachelt',
             'Greg Lahaie': 'Greg LaHaie',
             'KAT': 'Kantishna Air Taxi',
             'KRH': 'Kantishna Roadhouae',
             'Virginia Wood': 'Ginny Wood',
             'Ginny Woods': 'Ginny Wood',
             'Ray Kreig': 'Ray Krieg'}



def main(out_dir, search_dir = r'C:\Users\shooper\proj\savagedb\db\merged_tables'):

    #if not os.path.isdir(out_dir):
    #    os.mkdir(out_dir)

    # Copy all tables to out_dir if it's different from search_dir
    if not search_dir == out_dir:
        if os.path.isdir(out_dir):
            shutil.rmtree(out_dir)
        shutil.copytree(search_dir, out_dir)
        search_dir = out_dir # now just modify files in out_dir

    # Format dates here because each time to_csv() writes the data, it does so as a string without formatting
    print 'Fixing datetime formatting...\n'
    for table in TABLES_WITH_DATES:
        csv = os.path.join(search_dir, '%s.csv' % table)
        df = pd.read_csv(csv)
        '''if 'obs_date' in df.columns:
            df.obs_date = pd.to_datetime(df.obs_date, format='%Y-%m-%d %H:%M:%S') \
                .dt.strftime('%Y/%m/%d')
        # Don't need to do anything with timestamps because pandas uses the format postgres expects'''
        date_column = df.columns[df.columns.str.endswith('date')].any() # returns 1st if one exists
        drop_columns = [date_column]
        if date_column:
            if 'time' in df.columns:

                # combine date and time in the format postgres expects from a timestamp string
                df['datetime'] = df[date_column].str.split().apply(lambda x: x[0]) + \
                                 pd.Series([' '] * len(df)) + \
                                 df['time'].str.split().apply(lambda x: x[1] if type(x) != float else '00:00:00')
                drop_columns.append('time')

            else:
                # Just format the date since there is no time
                df.obs_date = pd.to_datetime(df.obs_date, format='%Y-%m-%d %H:%M:%S') \
                    .dt.strftime('%Y/%m/%d')

            # If there's no date, the record is useless anyway so drop it
            df = df.loc[~df[date_column].isnull()]

        df.drop(drop_columns, axis=1, inplace=True)

        df.to_csv(csv, index=False)

    # Rename here because renaming in _premerge screws up the code
    print '\nRenaming workgroup text files...\n'
    os.rename(os.path.join(out_dir, 'greenstudy.csv'), os.path.join(out_dir, 'admin_use.csv'))
    os.rename(os.path.join(out_dir, 'greenstudywg.csv'), os.path.join(out_dir, 'nps_work_groups.csv'))
    os.rename(os.path.join(out_dir, 'greenstudytp.csv'), os.path.join(out_dir, 'nps_trip_purpose.csv'))

    print '\nSplitting nonbus table...\n'
    nonbus_txt = os.path.join(search_dir, 'nonbus.csv')
    nonbus = pd.read_csv(nonbus_txt)
    nonbus['nid'] = nonbus['id']
    nonbus['id'] = xrange(len(nonbus))

    for key, grouped in nonbus.groupby('entrytype'):
        grouped.drop('entrytype', axis=1, inplace=True)

        # add new columns and remove unnecessary ones
        these_fields = CONSTANT_FIELDS + NONBUS_FIELDS[key]
        for field in these_fields:
            if field not in grouped.columns:
                grouped[field] = ''
        grouped = grouped.loc[:, these_fields]
        grouped.to_csv(os.path.join(search_dir, '%s.csv' % CODES[key]), index=False)

    os.remove(nonbus_txt)

    print 'Removing duplicates from ...',
    print 'employees...',
    employee_txt = os.path.join(out_dir, 'employees.csv')
    employees = pd.read_csv(employee_txt)
    employee_names = employees.employee_name.sort_values().apply(lambda x: titlecase(x)).unique()
    employees = pd.DataFrame({'employee_id': range(1, len(employee_names) + 1),
                              'employee_name': employee_names})
    employees.to_csv(employee_txt, index=False)

    print 'destination_codes...',
    dest_codes_txt = os.path.join(out_dir, 'destination_codes.csv')
    dest_codes = pd.read_csv(dest_codes_txt)
    dest_codes.drop_duplicates('codename', inplace=True)
    dest_codes.rename(columns={'cid': 'id'}, inplace=True)
    dest_codes.id = range(len(dest_codes))
    dest_codes.to_csv(dest_codes_txt, index=False)

    print 'bus_codes...\n\n'
    bus_codes_txt = os.path.join(out_dir, 'bus_codes.csv')
    bus_codes = pd.read_csv(bus_codes_txt)
    bus_codes.drop_duplicates('codename', inplace=True)
    bus_codes.rename(columns={'cid': 'id'}, inplace=True)
    bus_codes.id = range(len(bus_codes))
    bus_codes.to_csv(bus_codes_txt, index=False)

    print 'Renaming "bustraffic" to "buses"...\n'
    buses_txt = os.path.join(search_dir, 'bustraffic.csv')
    buses = pd.read_csv(buses_txt)
    buses.sort_values(['datetime'], inplace=True)
    buses['id'] = xrange(len(buses))
    buses.to_csv(os.path.join(search_dir, 'buses.csv'), index=False)
    os.remove(buses_txt)

    print 'Deleting "researcher" and "codenames" tables...\n'
    researcher_txt = os.path.join(search_dir, 'researcher.csv')
    if os.path.isfile(researcher_txt):
        os.remove(researcher_txt)
    codenames_txt = os.path.join(search_dir, 'codenames.csv')
    if os.path.isfile(codenames_txt):
        os.remove(codenames_txt)

    print 'Pivoting right-of-way allotments and renaming to "inholder_allotments"...\n'
    row_txt = os.path.join(search_dir, 'row_max.csv')
    inholder_allotments = pd.read_csv(row_txt)
    inholder_allotments.replace({'permitholder': ROW_NAMES}, inplace=True)
    inholder_allotments = inholder_allotments.pivot(index='permitholder', columns='year', values='totalallowed')
    inholder_allotments.rename_axis('permit_holder', axis=0, inplace=True)
    inholder_allotments.rename(columns={c: '_%s' % c for c in inholder_allotments.columns}, inplace=True)
    inholder_allotments.to_csv(os.path.join(search_dir, 'right_of_way_allotments.csv'))

    os.remove(row_txt)

    print 'Adding ID field to all tables...\n'
    for csv in glob(os.path.join(search_dir, '*.csv')):
        df = pd.read_csv(csv)
        if 'id' not in df.columns:
            df['id'] = 0
        df.id = xrange(len(df))
        df.to_csv(csv, index=False)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

