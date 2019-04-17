import sys
import os
import shutil
import warnings
import subprocess
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db, get_lookup_table



DUPLICATE_FIELDS_ALL = ['datetime', 'n_passengers', 'destination', 'comments']
DUPLICATE_FIELDS_TBL = {'accessibility': [],
                        'buses': ['bus_type', 'bus_number', 'is_training', 'n_lodge_ovrnt'],
                        'cyclists': [],
                        'employee_vehicles': ['permit_number', 'permit_holder'],
                        'inholders': ['permit_holder', 'permit_number'],
                        'nps_approved': ['permit_number', 'approved_type', 'n_nights'],
                        'nps_contractors': ['n_nights', 'organization', 'project_type'],
                        'nps_vehicles': ['n_nights', 'trip_purpose', 'work_group'],
                        'photographers': ['n_nights', 'permit_number'],
                        'road_lottery': [],
                        'subsistence': ['permit_number'],
                        'other_vehicles': [],
                        'tek_campers': []}

LOOKUP_FIELDS = pd.DataFrame([['buses', 'bus_type', 'bus_codes', 'code', 'name'],
                              ['nps_approved', 'approved_type', 'nps_approved_codes', 'code', 'name'],
                              ['nps_vehicles', 'work_group', 'nps_work_groups', 'code', 'name'],
                              ['inholders', 'permit_holder', 'inholder_allotments', 'inholder_code', 'inholder_name'],
                              ['nps_vehicles', 'work_group', 'nps_work_groups', 'code', 'name'],
                              ['nps_vehicles', 'trip_purpose', 'nps_trip_purposes', 'code', 'name'],
                              ['nps_contractors', 'project_type', 'contractor_project_types', 'code', 'name']
                              ],
                             columns=['data_table', 'data_field', 'lookup_table', 'lookup_index', 'lookup_value'])\
                        .sort_values(['data_table', 'data_field'])\
                        .set_index(['data_table', 'data_field'])


def get_missing_lookup(data, table_name, data_field, engine, lookup_params):
    lookup_values = get_lookup_table(engine, lookup_params.lookup_table, lookup_params.lookup_index,
                                     lookup_params.lookup_value) \
        .values()  # returns dict, but only need list-like
    missing_lookup = data.loc[~data[data_field].isin(lookup_values), data_field].unique()
    n_missing = len(missing_lookup)
    missing_info = pd.DataFrame({'data_value': missing_lookup,
                                 'data_table': [table_name for _ in range(n_missing)],
                                 'data_field': [data_field for _ in range(n_missing)],
                                 'lookup_table': [lookup_params.lookup_table for _ in range(n_missing)],
                                 'lookup_field': [lookup_params.lookup_value for _ in range(n_missing)]})

    return missing_info


def main(sqlite_path, connection_txt):

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    sqlite_engine = create_engine("sqlite:///" + sqlite_path)
    postgres_engine = connect_db(connection_txt)
    # Get list of all tables in the master DB
    with postgres_engine.connect() as pg_conn, pg_conn.begin():
        postgres_tables = pd.read_sql("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';",
                                      pg_conn)\
                                      .squeeze()\
                                      .tolist()
        pg_shift_info = pd.read_sql_table('shift_info', pg_conn, index_col='id')

    # Get data from app
    with sqlite_engine.connect() as sl_conn, sl_conn.begin():
        sqlite_tables = pd.read_sql("SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%') AND name NOT "
                                    "LIKE('sessions');",
                                    sl_conn)\
                                    .squeeze()
        data = {table_name: pd.read_sql("SELECT * FROM %s" % table_name, sl_conn, index_col='id')
                for table_name in sqlite_tables}
        sl_shift_info = pd.read_sql("SELECT * FROM sessions", sl_conn).squeeze()

    if 'imported' in sl_shift_info.index:
        if sl_shift_info.imported:
            raise RuntimeError("These data have already been uploaded")

    # Make temp dir and set up vars for looping through tables
    output_dir = os.path.join(os.path.dirname(sqlite_path), '_temp')
    if not os.path.isdir(output_dir):
        os.mkdir(output_dir)
    subprocess.call(["attrib", "+H", output_dir])

    destination_values = get_lookup_table(postgres_engine, 'destination_codes').values

    missing_lookup_dfs = []
    for table_name, df in data.iteritems():

        if table_name == 'observations':
            continue

        # Check that the table exists in the master DB. If not, skip it.
        if table_name not in postgres_tables:
            warnings.warn('Table named "{table_name}" not found in database. Database tables are: \n\t\t{pg_tables}'
                          .format(table_name=table_name, pg_tables='\n\t\t'.join(postgres_tables)))
            continue

        # Combine date and time columns
        df['datetime'] = pd.to_datetime(df.date + ' ' + df.time)  # format should be automatically undersood
        df.drop(['date', 'time'], axis=1, inplace=True)

        flagged_path = os.path.join(output_dir, '%s_flagged.csv' % table_name)
        # Check for duplicates within the DB from the app
        duplicate_columns = [c for c in DUPLICATE_FIELDS_ALL + DUPLICATE_FIELDS_TBL[table_name] if c in df.columns]
        sl_duplicates = df.loc[df.duplicated(subset=duplicate_columns, keep=False)]# keep=false keeps all dups
        sl_duplicates['duplicated_in_app'] = True

        # Check for duplicates with the Postgres db. Limit the check to only Postgres records from this year to
        #   reduce read times
        with postgres_engine.connect() as pg_conn, pg_conn.begin():
            pg_data = pd.read_sql("SELECT * FROM {table_name} WHERE extract(year FROM datetime) = {year}"
                                  .format(table_name=table_name, year=datetime.now().year),
                                  pg_conn)
        all_data = pd.concat([pg_data, df], sort=False)
        # Get all indices from all rows in df whose duplicate columns match those in the master DB
        is_pg_duplicate = all_data.duplicated(subset=duplicate_columns, keep=False)
        pg_duplicates = df.loc[df.index.isin(all_data.loc[is_pg_duplicate].index)]
        pg_duplicates['found_in_db'] = True

        duplicates = pd.concat([sl_duplicates, pg_duplicates], sort=False)
        # In case any records were duplicated in the app and the DB, reduce the df by the index. max() will return
        #   True/False if one of the repeated indices is NaN, but another is True/False. All other columns should
        #   be identical since a duplicated index represents the same record from the sqlite DB
        duplicates = duplicates.groupby(duplicates.index).max()

        df['duplicated_in_app'] = False
        df['found_in_db'] = False
        if len(sl_duplicates):
            df.loc[duplicates.index, 'duplicated_in_app'] = duplicates.duplicated_in_app
        if len(pg_duplicates):
            df.loc[duplicates.index, 'found_in_db'] = duplicates.found_in_db

        # If this table contains any lookup values, check to see if all data values exist in the corresponding
        #  lookup table
        if 'destination' in df.columns:
            destination_lookup_params = pd.Series({'data_table': table_name,
                                                   'lookup_table': 'destination_codes', 'lookup_index': 'code',
                                                   'lookup_value': 'name'})
            missing_info = get_missing_lookup(df, table_name, 'destination', postgres_engine, destination_lookup_params)
            if len(missing_info) > 0:
                missing_lookup_dfs.append(missing_info)

        if table_name in LOOKUP_FIELDS.index:
            for data_field, lookup_params in LOOKUP_FIELDS.loc[table_name].iterrows():
                missing_info = get_missing_lookup(df, table_name, data_field, postgres_engine, lookup_params)
                if len(missing_info) > 0:
                    missing_lookup_dfs.append(missing_info)

        # Access expects datetimes in the format mm/dd/yy hh:mm:ss so reformat it
        df.datetime = df.datetime.dt.strftime('%m/%d/%Y %H:%M:%S')
        df.to_csv(flagged_path)

    # If there were any missing lookup values, save the CSV
    if len(missing_lookup_dfs) > 0:
        missing_lookup = pd.concat(missing_lookup_dfs)
        missing_lookup.to_csv(os.path.join(output_dir, 'missing_lookup_values_flagged.csv'), index=False)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))








