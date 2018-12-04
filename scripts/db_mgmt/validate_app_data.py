import sys
import os
import shutil
import warnings
import sqlite3
import docopt
import pandas as pd
from datetime import datetime
from sqlalchemy import create_engine




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

def connect_db(connection_txt):

    connection_info = {}
    with open(connection_txt) as txt:
        for line in txt.readlines():
            if ';' not in line:
                continue
            param_name, param_value = line.split(';')
            connection_info[param_name.strip()] = param_value.strip()

    try:
        engine = create_engine(
            'postgresql://{username}:{password}@{ip_address}:{port}/{db_name}'.format(**connection_info))
    except:
        message = '\n' + '\n\t'.join(['%s: %s' % (k, v) for k, v in connection_info.iteritems()])
        raise ValueError('could not establish connection with parameters:%s' % message)

    return engine


def main(sqlite_path, connection_txt, archive_dir=None, mode='validate'):

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
        data = {table_name: pd.read_sql("SELECT * FROM %s" % table_name, sl_conn).set_index('id')
                for table_name in sqlite_tables}
        shift_info = pd.read_sql("SELECT * FROM sessions", sl_conn).squeeze()

    if shift_info.imported:
        raise RuntimeError("These data have already been uploaded")

    # Make temp dir and set up vars for looping through tables
    duplicate_dir = os.path.join(os.path.dirname(sqlite_path), '_temp')
    if not os.path.isdir(duplicate_dir):
        os.mkdir(duplicate_dir)
    #flagged_path = os.path.join(duplicate_dir, 'flagged.csv')
    duplicates_found = False
    for table_name, df in data.iteritems():

        # Check that the table exists in the master DB. If not, skip it.
        if table_name not in postgres_tables:
            warnings.warn('Table named "{table_name}" not found in database. Database tables are: \n\t\t{pg_tables}'
                          .format(table_name=table_name, pg_tables='\n\t\t'.join(postgres_tables)))
            continue

        if mode == 'validate':

            # Combine date and time columns
            df['datetime'] = pd.to_datetime(df.date + ' ' + df.time)  # format should be automatically undersood
            df.drop(['date', 'time'], axis=1, inplace=True)

            flagged_path = os.path.join(duplicate_dir, '%s_flagged.csv' % table_name)
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

            # Continue to the next table if checking duplicates for the first time
            continue

        # The data have already been checked so import the data to the DB
        elif mode == 'import':
            checked_duplicates_csv = os.path.join('%s_checked.csv' % table_name)

            if os.path.isfile(checked_duplicates_csv):
                # Because access can't handle datetimes in the default SQL format, it had to be converted to something Access could handle. So now, make it a datetime again
                checked_duplicates = pd.read_csv(checked_duplicates_csv, index_col='id', parse_dates=['datetime'])
                all_duplicates = pd.read_csv(checked_duplicates_csv.replace('_checked.csv', '.csv'), index_col='id')
                # Combine just the duplicates that were checked and the data that were not flagged as duplicates
                df = df.loc[all_duplicates.index.isin(checked_duplicates.index) |
                            ~df.index.isin(all_duplicates)]
        # If we got here, the data have already been checked for duplicates, so append the new data to the DB table if there are any records
        if len(df):
            with postgres_engine.connect() as pg_conn, pg_conn.begin():
                postgres_columns = pd.read_sql("SELECT column_name FROM information_schema.columns "
                                               "WHERE table_name = '{}' AND table_schema = 'public';"
                                               .format(table_name), pg_conn)\
                                                .squeeze()
                df.drop([c for c in df if c not in postgres_columns] + ['id'], axis=1, inplace=True)
                import pdb; pdb.set_trace()
                df.to_sql(table_name, pg_conn, if_exists='append', index=False)

        else:
            raise ValueError('mode "%s" not understood' % mode)

    # Stop here if any duplicates were found
    if duplicates_found:
        import pdb; pdb.set_trace()
        sys.exit()


    # Update the imported column
    if mode == 'import':
        try:
            sqlite_engine.execute("UPDATE sessions SET imported = 1;")
        except:
            warnings.warn("Failed to update 'imported' field in the data from the app. If you try to run this script again,"
                          "it will not warn you that these data have already been uploaded.")

        # Copy the sqlite db to the archive
        if not os.path.isdir(archive_dir):
            try:
                os.mkdir(archive_dir)
                shutil.copy(sqlite_path, archive_dir)
            except:
                pass
        #shutil.copy(sqlite_path, archive_dir)

        # Clean up the text files created by this script
        shutil.rmtree(duplicate_dir)

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))








