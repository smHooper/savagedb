import sys
import os
import shutil
import warnings
import subprocess
import sqlite3
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db, get_lookup_table



DUPLICATE_FIELDS_ALL = ['datetime', 'n_passengers', 'destination', 'comments']
DUPLICATE_FIELDS_TBL = {'accessibility': [],
                        'buses': ['bus_type', 'bus_number', 'is_training', 'n_lodge_ovrnt'],
                        'cyclists': [],
                        'employee_vehicles': ['permit_number', 'permit_holder', 'driver_name'],
                        'inholders': ['permit_holder', 'permit_number', 'driver_name'],
                        'nps_approved': ['permit_number', 'approved_type', 'n_nights', 'permit_holder'],
                        'nps_contractors': ['n_nights', 'organization', 'permit_number'],
                        'nps_vehicles': ['n_nights', 'trip_purpose', 'work_group'],
                        'photographers': ['n_nights', 'permit_number'],
                        'road_lottery': [],
                        'subsistence': ['permit_number'],
                        'other_vehicles': [],
                        'tek_campers': []}

LOOKUP_FIELDS = pd.DataFrame([['buses', 'bus_type', 'bus_codes', 'code', 'name'],
                              ['nps_approved', 'approved_type', 'nps_approved_codes', 'code', 'name'],
                              ['inholders', 'permit_holder', 'inholder_allotments', 'inholder_code', 'inholder_name'],
                              ['nps_vehicles', 'work_group', 'nps_work_groups', 'code', 'name'],
                              ['nps_vehicles', 'trip_purpose', 'nps_trip_purposes', 'code', 'name']
                              ],
                             columns=['data_table', 'data_field', 'lookup_table', 'lookup_index', 'lookup_value'])\
                        .sort_values(['data_table', 'data_field'])\
                        .set_index(['data_table', 'data_field'])

# SQLite doesn't have a boolean datatype (they're stored as int) so
BOOLEAN_FIELDS = {'buses': ['is_training', 'is_overnight']}


def replace_lookup_values(data, engine, data_field, lookup_params):

    lookup_values = get_lookup_table(engine, lookup_params.lookup_table, lookup_params.lookup_value,
                                     lookup_params.lookup_index)
    invalid_values = data.loc[data[data_field].isin(lookup_values.values()) & ~data[data_field].isnull(), data_field].unique()
    if len(invalid_values):
        raise ValueError('The following entries for the field {field} in table {table} were invalid:\n\t-{values}'
                         .format(field=data_field,
                                 table=lookup_params.data_table,
                                 values='\n\t-'.join(invalid_values)))
    data.replace({data_field: lookup_values}, inplace=True)
    data[[data_field]] = data[[data_field]].fillna(value='NUL') # make sure any empty data are marked as NUL, which should be in every lookup table


    return data


def clean_app_data(data, sqlite_data, table_name, postgres_engine):
    '''Replace full names with codes and correct boolean fields since SQLite doesn't have a boolean dtype'''

    df = data.copy()
    with postgres_engine.connect() as conn, conn.begin():
        pg_data = pd.read_sql("SELECT * FROM %s LIMIT 1" % table_name, conn)
    for c in df.columns:
        if c in sqlite_data.columns:
            dtype = sqlite_data[c].dtype
            if table_name in BOOLEAN_FIELDS:
                if c in BOOLEAN_FIELDS[table_name]:
                    dtype = bool
            df[c] = df[c].astype(dtype)
        if c in pg_data.columns:
            df[c] = df[c].astype(pg_data[c].dtype)


    if 'destination' in df.columns:
        destination_lookup_params = pd.Series({'data_table': table_name,
                                               'lookup_table': 'destination_codes', 'lookup_index': 'code',
                                               'lookup_value': 'name'})
        df = replace_lookup_values(df, postgres_engine, 'destination', destination_lookup_params)
    if table_name in LOOKUP_FIELDS.index:
        for data_field, lookup_params in LOOKUP_FIELDS.loc[table_name].iterrows():
            df = replace_lookup_values(df, postgres_engine, data_field, lookup_params)
            if lookup_params.lookup_index == 'inholder_code':
                df['inholder_code'] = df.permit_holder

    return df


def get_missing_lookup(data, table_name, data_field, engine, lookup_params):
    lookup_values = get_lookup_table(engine, lookup_params.lookup_table, lookup_params.lookup_index,
                                     lookup_params.lookup_value) \
        .values()  # returns dict, but only need list-like
    # Ignore data == "" because this will just be changed to NUL in the import process
    missing_lookup = data.loc[~data[data_field].isin(lookup_values) & (data[data_field] != ''), data_field].unique()
    n_missing = len(missing_lookup)
    missing_info = pd.DataFrame({'data_value': missing_lookup,
                                 'data_table': [table_name for _ in range(n_missing)],
                                 'data_field': [data_field for _ in range(n_missing)],
                                 'lookup_table': [lookup_params.lookup_table for _ in range(n_missing)],
                                 'lookup_field': [lookup_params.lookup_value for _ in range(n_missing)]})

    return missing_info


def combine_sqlite_dbs(sqlite_paths_str, delimiter=";"):

    db_paths = sqlite_paths_str.split(delimiter)

    # Create a single db to combine all the data into by copying the first db
    combined_path = os.path.join(os.path.dirname(db_paths[0]), 'combined_data.db')
    shutil.copy2(db_paths[0], combined_path)
    conn = sqlite3.connect(combined_path)

    # Get all table names. These should be the same for all DBs
    table_names = pd.read_sql("SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%')", conn).squeeze()

    # Update the first db with the filename in all tables
    for table in table_names:
        column_names = pd.read_sql("SELECT * FROM %s LIMIT 1" % table, conn).columns
        if 'filename' not in column_names: #might already be there if validate script was run before with this db
            conn.execute("ALTER TABLE {table} ADD COLUMN filename VARCHAR(255);"
                         .format(table=table))
        conn.execute("UPDATE {table} SET filename='{filename}';"
                     .format(table=table, filename=os.path.basename(db_paths[0])))
    conn.commit()

    for path in db_paths[1:]:

        # Update the the db to attach with it's filename
        conn_other = sqlite3.connect(path)
        for table in table_names:
            df = pd.read_sql("SELECT * FROM %s" % table, conn_other)
            df['filename'] = os.path.basename(path)
            df.drop(columns='id').to_sql(table, conn, if_exists='append', index=False)

    conn.close()

    return combined_path


def main(sqlite_paths_str, connection_txt):

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    sqlite_path = combine_sqlite_dbs(sqlite_paths_str)

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
        sl_shift_info = pd.read_sql("SELECT * FROM sessions", sl_conn)#.squeeze()

    if 'imported' in sl_shift_info.columns:#index:
        for _, this_shift_info in sl_shift_info.loc[~sl_shift_info.imported.isnull()].iterrows():
            if this_shift_info.imported:
                raise RuntimeError("These data have already been uploaded: %s" % this_shift_info.filename)

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
        all_data = pd.concat([pg_data, clean_app_data(df, df, table_name, postgres_engine)], sort=False, ignore_index=True)
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
        import pdb; pdb.set_trace()
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








