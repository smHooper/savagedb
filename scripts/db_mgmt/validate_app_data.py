import sys
import os
import shutil
import warnings
import subprocess
import unicodedata
import sqlite3
import pandas as pd
import numpy as np
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db, get_lookup_table

pd.options.mode.chained_assignment = None

DUPLICATE_FIELDS_ALL = ['datetime', 'n_passengers', 'destination', 'comments']
DUPLICATE_FIELDS_TBL = {'accessibility': [],
                        'buses': ['bus_type', 'bus_number', 'is_training', 'n_lodge_ovrnt'],
                        'cyclists': [],
                        'employee_vehicles': ['permit_number', 'permit_holder', 'driver_name'],
                        'inholders': ['inholder_code', 'permit_number', 'driver_name'],
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


def get_numeric_pg_fields(postgres_engine, table_name):
    with postgres_engine.connect() as conn, conn.begin():
        numeric_fields = pd.read_sql("SELECT column_name FROM information_schema.columns "
                                     "WHERE table_name = '%s' AND "
                                     "data_type IN ('smallint', 'integer', 'bigint', 'decimal', 'real', 'double precision', 'numeric')" % table_name,
                                     conn) \
            .squeeze()

    return numeric_fields


def check_numeric_fields(data, postgres_engine, table_name, filename=None):

    numeric_fields = get_numeric_pg_fields(postgres_engine, table_name)

    invalid_fields = []
    for field in numeric_fields:
        if field in data.columns:
            if data[field].dtype == np.object:
                if data[field].str.strip().str.contains('[^\d*]').fillna(False).any():
                    invalid_fields.append(field)

    if invalid_fields:
        raise ValueError('The following numeric fields in the table {table}{file} contain non-numeric characters:\n\t-{fields}'
                         .format(table=table_name,
                                 file=' from %s' % filename if filename else '',
                                 fields='\n\t-'.join(invalid_fields)
                                 )
                         )


def combine_sqlite_dbs(sqlite_paths_str, postgres_engine, delimiter=";"):

    db_paths = sqlite_paths_str.split(delimiter)

    # Create a single db to combine all the data into by copying the first db
    combined_path = os.path.join(os.path.dirname(db_paths[0]), 'combined_data.db')
    shutil.copy2(db_paths[0], combined_path)
    conn = sqlite3.connect(combined_path)

    # Get all table names. These should be the same for all DBs
    table_names = pd.read_sql("SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%')", conn).squeeze()

    # Update the first db with the filename in all tables
    data_tables = {}
    for table in table_names:
        column_names = pd.read_sql("SELECT * FROM %s LIMIT 1" % table, conn).columns
        if 'filename' not in column_names: #might already be there if validate script was run before with this db
            conn.execute("ALTER TABLE {table} ADD COLUMN filename VARCHAR(255);"
                         .format(table=table))
        filename = os.path.basename(db_paths[0])
        conn.execute("UPDATE {table} SET filename='{filename}';"
                     .format(table=table, filename=filename))
        df = pd.read_sql("SELECT * FROM %s" % table, conn)
        check_numeric_fields(df, postgres_engine, table, filename)
        data_tables[table] = df
    conn.commit()

    # Check if this first DB is empty. If not, add it to the list of paths that actually have data
    component_paths = []
    is_empty = sum([len(df) for name, df in data_tables.iteritems() if name not in ['sessions', 'observations']]) == 0
    if not is_empty:
        component_paths.append(db_paths[0])

    for path in db_paths[1:]:
        # Append the data (updated with its filename) to the combined db
        conn_other = sqlite3.connect(path)
        data_tables = {}
        for table in table_names:
            df = pd.read_sql("SELECT * FROM %s" % table, conn_other)
            df['filename'] = os.path.basename(path)
            check_numeric_fields(df, postgres_engine, table, os.path.basename(path))
            data_tables[table] = df.drop(columns='id')#.to_sql(table, conn, if_exists='append', index=False)

        # If the database isn't empty, append the data and add the path to the list of non-empty files
        is_empty = sum([len(df) for name, df in data_tables.iteritems() if name not in ['sessions', 'observations']]) == 0
        if not is_empty:
            for tname, df in data_tables.iteritems():
                df.to_sql(tname, conn, if_exists='append', index=False)
            component_paths.append(path)

        conn_other.close()
    conn.close()

    return combined_path, delimiter.join(component_paths)


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

    # .astype won't work on mixed dtypes, so set anything == '' to NaN
    null_mask = df == ''
    df[null_mask] = np.nan
    with postgres_engine.connect() as conn, conn.begin():
        pg_data = pd.read_sql("SELECT * FROM %s LIMIT 1" % table_name, conn)
    for c in df.columns:
        # Set datatypes for bools because sqlite stores them as 0-1 integers
        if c in sqlite_data.columns:
            dtype = sqlite_data[c].dtype
            if table_name in BOOLEAN_FIELDS:
                if c in BOOLEAN_FIELDS[table_name]:
                    dtype = bool
            df[c] = df[c].astype(dtype)
        # Make sure all dtypes match postgres dtypes. This probably covers the boolean dtype change above, but do both
        #  just to be sure
        if c in pg_data.columns:
            df.loc[~df[c].isnull(), c] = df.loc[~df[c].isnull(), c].astype(pg_data[c].dtype)

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

    if table_name == 'buses':
        try:
            data.loc[data.bus_type == 'TRN', 'is_training'] = True
        except:
            pass

    return df


def fill_null(df, numeric_fields):
    '''Make sure the NaN values are all the same for numeric and text fields. For text fields, somewhere NaNs
    (or just the 'comments' column) are getting filled with 'None' (could be NoneType but it's re-read as string)'''
    df[numeric_fields] = df[numeric_fields] \
        .fillna(0) \
        .astype(np.int64)
    df.loc[:, df.dtypes == np.object] = df.loc[:, df.dtypes == np.object].fillna('None')

    return df


def get_missing_lookup(data, table_name, data_field, engine, lookup_params):
    lookup_values = get_lookup_table(engine, lookup_params.lookup_table, lookup_params.lookup_index,
                                     lookup_params.lookup_value) \
        .values()  # returns dict, but only need list-like
    # Ignore data == "" because this will just be changed to NUL in the import process
    missing_mask = ~data[data_field].isin(lookup_values) & (data[data_field] != '')
    missing_lookup = data.loc[missing_mask, data_field].unique()
    n_missing = len(missing_lookup)
    missing_info = pd.DataFrame({'data_value': missing_lookup,
                                 'data_table': [table_name for _ in range(n_missing)],
                                 'data_field': [data_field for _ in range(n_missing)],
                                 'lookup_table': [lookup_params.lookup_table for _ in range(n_missing)],
                                 'lookup_field': [lookup_params.lookup_value for _ in range(n_missing)],
                                 'filename': data.loc[missing_mask, 'filename']})

    return missing_info


def main(sqlite_paths_str, connection_txt, output_dir=None):

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    postgres_engine = connect_db(connection_txt)
    sqlite_path, component_paths = combine_sqlite_dbs(sqlite_paths_str, postgres_engine)

    if not len(component_paths):
        raise RuntimeError('All data files are empty')

    sys.stdout.write('sqlite_paths: %s\n\n' % component_paths)
    sys.stdout.flush()

    sqlite_engine = create_engine("sqlite:///" + sqlite_path)
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
    output_dir = os.path.join(os.path.dirname(sqlite_path), '_temp') if not output_dir else output_dir
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

        # If there's no data in this table, write the empty dataframe and continue
        flagged_path = os.path.join(output_dir, '%s_flagged.csv' % table_name)
        if not len(df):
            df.to_csv(flagged_path, index=False, encoding='utf-8')
            continue

        # Clean up unicode strings so sqlalchemy doesn't freak out when importing
        df.loc[:, df.dtypes == object] = df.loc[:, df.dtypes == object]\
            .applymap(lambda x: x if x == None else str(unicodedata.normalize('NFKD', x)))

        # Combine date and time columns
        df['datetime'] = pd.to_datetime(df.date + ' ' + df.time)  # format should be automatically undersood
        df.drop(['date', 'time'], axis=1, inplace=True)

        # Check for duplicates within the DB from the app
        duplicate_columns = [c for c in DUPLICATE_FIELDS_ALL + DUPLICATE_FIELDS_TBL[table_name] if c in df.columns]
        sl_duplicates = df.loc[df.duplicated(subset=duplicate_columns, keep=False)].copy()# keep=false keeps all dups
        sl_duplicates['duplicated_in_app'] = True

        # Check for duplicates with the Postgres db. Limit the check to only Postgres records from this year to
        #   reduce read times
        numeric_fields = pd.Series([f for f in get_numeric_pg_fields(postgres_engine, table_name) if f in df.columns])
        if hasattr(numeric_fields, '__iter__'):
            numeric_fields = numeric_fields[numeric_fields.isin(duplicate_columns)]# & numeric_fields.isin(df.columns)]
        with postgres_engine.connect() as pg_conn, pg_conn.begin():
            pg_data = pd.read_sql("SELECT * FROM {table_name} WHERE extract(year FROM datetime) = {year}"
                                  .format(table_name=table_name, year=datetime.now().year),
                                  pg_conn)

        # If there are no data in the DB for this table, the pd.merge() line will balk because the column dtypes to
        #   merge on won't match. So check, and create an empty dataframe if true
        if len(pg_data):
            cleaned_data = clean_app_data(df, df, table_name, postgres_engine)

            # Get all indices from all rows in df whose duplicate columns match those in the master DB.
            cleaned_data['id_'] = cleaned_data.index
            merged = pd.merge(fill_null(cleaned_data, numeric_fields),
                                        fill_null(pg_data, numeric_fields),
                                        on=duplicate_columns, how='left', indicator='exists')
            is_pg_duplicate = (merged.drop_duplicates('id_').exists == 'both').values # pd.merge creates a new index so just get array of bool values
            cleaned_data['found_in_db'] = is_pg_duplicate
            pg_duplicates = cleaned_data.loc[cleaned_data.found_in_db]
        else:
            # Still need the found_in_db column though because
            pg_duplicates = pd.DataFrame()

        duplicates = pd.concat([sl_duplicates, pg_duplicates], sort=False)

        # In case any records were duplicated in the app and the DB, reduce the df by the index. max() will return
        #   True/False if one of the repeated indices is NaN but another is True/False. All other columns should
        #   be identical since a duplicated index represents the same record from the sqlite DB
        duplicates = duplicates.groupby(duplicates.index)\
            .max()\
            .fillna(False)

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

        # This is possibly one of the dumbest things I've ever had to do in code, but Access doesn't handle columns
        #  with mixed data types well -- it will sometimes assume that a column containing both integers and text as
        #  integer, meaning the text rows will fail to import. To force Access to read all of it as text, make the
        #  first 50 rows all nonsense text. These rows will then be deleted as soon as they're imported.
        df = pd.concat([pd.DataFrame(np.full((50, len(df.columns)), 'aaaa'), columns=df.columns),
                        df])

        df.to_csv(flagged_path, index=False, encoding='utf-8')

    # If there were any missing lookup values, save the CSV
    if len(missing_lookup_dfs) > 0:
        missing_lookup = pd.concat(missing_lookup_dfs)
        missing_lookup.to_csv(os.path.join(output_dir, 'missing_lookup_values_flagged.csv'), index=False)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))








