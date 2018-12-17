import sys
import os
import shutil
import warnings
import subprocess
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db



DUPLICATE_FIELDS_ALL = ['datetime', 'n_passengers', 'destination', 'comments']
DUPLICATE_FIELDS_TBL = {'accessibility': [],
                        'buses': ['bus_type', 'bus_number', 'is_training', 'n_lodge_ovrnt'],
                        'cyclists': [],
                        'employee_vehicles': ['permit_number'],
                        'inholders': ['permit_holder', 'permit_number'],
                        'nps_approved': ['approved_type', 'n_nights'],
                        'nps_contractors': ['n_nights', 'organization', 'trip_purpose'],
                        'nps_vehicles': ['n_nights', 'trip_purpose', 'work_division', 'work_group'],
                        'photographers': ['n_nights', 'permit_number'],
                        'road_lottery': ['permit_number'],
                        'subsistence': [],
                        'other_vehicles': [],
                        'tek_campers': []}


def main(sqlite_path, connection_txt):

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.flush()

    sqlite_engine = create_engine("sqlite:///" + sqlite_path)
    postgres_engine = connect_db(connection_txt)
    # Get list of all tables in the master DB
    with postgres_engine.connect() as pg_conn, pg_conn.begin():
        postgres_tables = pd.read_sql("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';",
                                      pg_conn)\
                                      .squeeze()\
                                      .tolist()
    # Get data from app
    with sqlite_engine.connect() as sl_conn, sl_conn.begin():
        sqlite_tables = pd.read_sql("SELECT name FROM sqlite_master WHERE name NOT LIKE('sqlite%') AND name NOT "
                                    "LIKE('sessions');",
                                    sl_conn)\
                                    .squeeze()
        data = {table_name: pd.read_sql("SELECT * FROM %s" % table_name, sl_conn, index_col='id')
                for table_name in sqlite_tables}
        shift_info = pd.read_sql("SELECT * FROM sessions", sl_conn).squeeze()

    if 'imported' in shift_info.index:
        if shift_info.imported:
            raise RuntimeError("These data have already been uploaded")

    # Make temp dir and set up vars for looping through tables
    output_dir = os.path.join(os.path.dirname(sqlite_path), '_temp')
    if not os.path.isdir(output_dir):
        os.mkdir(output_dir)
    subprocess.call(["attrib", "+H", output_dir])
    
    for table_name, df in data.iteritems():

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

        #import pdb; pdb.set_trace()

        # Access expects datetimes in the format dd/mm/yy hh:mm:ss so reformat it
        df.datetime = df.datetime.dt.strftime('%m/%d/%Y %H:%M:%S')
        df.to_csv(flagged_path)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))







