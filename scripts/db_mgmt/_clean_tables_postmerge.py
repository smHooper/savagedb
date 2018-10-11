

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

BUS_CODES = {'D': 'Denali Natural History Tour',
             'T': 'Tundra Wilderness Tour',
             'K': 'Kantishna Roadhouse',
             'B': 'Denali Backcountry Lodge',
             'O': 'Other',
             'E': 'Kantishna Experience',
             'M': 'McKinley Gold Camp',
             'I': 'Windows Into Wilderness'}

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

    print '\nSplitting nonbus table...\n'
    nonbus_txt = os.path.join(search_dir, 'nonbus.csv')
    nonbus = pd.read_csv(nonbus_txt)

    for key, grouped in nonbus.groupby('entrytype'):
        grouped.drop('entrytype', axis=1, inplace=True)

        # add new columns and remove unnecessary ones
        these_fields = CONSTANT_FIELDS + NONBUS_FIELDS[key]
        for field in these_fields:
            if field not in grouped.columns:
                grouped[field] = ''
        grouped = grouped.loc[:, these_fields]
        grouped['id'] = xrange(len(grouped))
        grouped.to_csv(os.path.join(search_dir, '%s.csv' % CODES[key]), index=False)

    os.remove(nonbus_txt)

    print 'Removing duplicates from ...',
    print 'employees...', # Right now this table is deleted, but keep this in case I change that later
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
    dest_codes.drop('explanation', axis=1, inplace=True)
    dest_codes.loc[dest_codes.codename == 'Stony', 'codename'] = 'Stony Overlook'
    dest_codes.rename(columns={'cid': 'id'}, inplace=True)
    dest_codes.id = range(len(dest_codes))
    dest_codes.to_csv(dest_codes_txt, index=False)

    print 'bus_codes...\n\n'
    bus_codes_txt = os.path.join(out_dir, 'bus_codes.csv')
    bus_codes = pd.read_csv(bus_codes_txt)
    bus_codes.drop_duplicates('codeletter', inplace=True)
    bus_codes.drop('explanation', axis=1, inplace=True)
    for letter, name in BUS_CODES.iteritems():
        bus_codes.loc[bus_codes.codeletter == letter, 'codename'] = name
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

    print 'Renaming "right_of_way" to "inholders"...\n'
    os.rename(os.path.join(search_dir, 'right_of_way.csv'), os.path.join(search_dir, 'inholders.csv'))

    print 'Deleting unnecessary tables...',
    researcher_txt = os.path.join(out_dir, 'researcher.csv')
    if os.path.isfile(researcher_txt):
        print 'researcher...',
        os.remove(researcher_txt)
    codenames_txt = os.path.join(out_dir, 'codenames.csv')
    if os.path.isfile(codenames_txt):
        print 'codenames...',
        os.remove(codenames_txt)
    greenstudy_txt = os.path.join(out_dir, 'greenstudy.csv')
    if os.path.isfile(greenstudy_txt):
        print 'greenstudy...',
        os.remove(greenstudy_txt)
    greenstudywg_txt = greenstudy_txt.replace('.csv', 'wg.csv')
    if os.path.isfile(greenstudywg_txt):
        print 'greenstudywg...',
        os.remove(greenstudywg_txt)
    greenstudytp_txt = greenstudy_txt.replace('.csv', 'tp.csv')
    if os.path.isfile(greenstudytp_txt):
        print 'greenstudytp...',
        os.remove(greenstudytp_txt)
    gmp_txt = os.path.join(out_dir, 'gmp.csv')
    if os.path.isfile(codenames_txt):
        print 'gmp...',
        os.remove(gmp_txt)
    datadates_txt = os.path.join(out_dir, 'datadates.csv')
    if os.path.isfile(codenames_txt):
        print 'datadates...',
        os.remove(datadates_txt)
    employees_txt = os.path.join(out_dir, 'employees.csv')
    if os.path.isfile(codenames_txt):
        print 'employees...',
        os.remove(employees_txt)
    print '\n\n'

    print 'Pivoting right-of-way allotments and renaming to "inholder_allotments"...\n'
    row_txt = os.path.join(search_dir, 'row_max.csv')
    inholder_allotments = pd.read_csv(row_txt)
    inholder_allotments.replace({'permitholder': ROW_NAMES}, inplace=True)
    inholder_allotments = inholder_allotments.pivot(index='permitholder', columns='year', values='totalallowed')
    inholder_allotments.rename_axis('permit_holder', axis=0, inplace=True)
    inholder_allotments.rename(columns={c: '_%s' % c for c in inholder_allotments.columns}, inplace=True)
    inholder_allotments.to_csv(os.path.join(search_dir, 'inholder_allotments.csv'))
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
