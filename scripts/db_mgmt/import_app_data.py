import sys
import os
import shutil
import warnings
import subprocess
import pandas as pd
from glob import glob
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db, get_lookup_table
from validate_app_data import LOOKUP_FIELDS, replace_lookup_values, BOOLEAN_FIELDS, clean_app_data


def main(data_dir, sqlite_path, connection_txt, archive_dir="", data_files=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    postgres_engine = connect_db(connection_txt)
    sqlite_engine = create_engine("sqlite:///" + sqlite_path)

    # Check if this date already exists in the shift_info table.
    #  Wrap the whole import block in the with .connect() context manager to run everything as a transaction that is
    #  automatically rolled back on error
    with postgres_engine.connect() as pg_conn, pg_conn.begin():
        pg_shift_info = pd.read_sql_table('shift_info', pg_conn, index_col='id')
        with sqlite_engine.connect() as sl_conn, sl_conn.begin():
            shift_info_data = pd.read_sql("SELECT * FROM sessions", sl_conn)#.squeeze()

        for _, sl_shift_info in shift_info_data.iterrows():
            pg_shift_info['date_str'] = pg_shift_info.open_time.dt.strftime('%Y%m%d')
            sl_open_time = pd.to_datetime('%(date)s %(open_time)s' % sl_shift_info)
            sl_close_time = pd.to_datetime('%(date)s %(close_time)s' % sl_shift_info)

            # If it exists, replace the open and close times with the earliest and latest, respectively
            if (pg_shift_info.date_str == sl_open_time.strftime('%Y%m%d')).any():
                id = pg_shift_info.loc[pg_shift_info.date_str == sl_open_time.strftime('%Y%m%d')].iloc[0].name
                pg_open_time = pg_shift_info.loc[id, 'open_time']
                pg_close_time = pg_shift_info.loc[id, 'close_time']
                open_time = min(pg_open_time, sl_open_time)
                close_time = max(pg_close_time, sl_close_time)
                sql = "UPDATE shift_info SET open_time = '%s', close_time = '%s' WHERE id=%s;" % (open_time, close_time, id)
            else:
                sql = "INSERT INTO shift_info (open_time, close_time, shift_date) VALUES ('%s', '%s', '%s')" % \
                      (sl_open_time, sl_close_time, sl_open_time.strftime('%Y-%m-%d'))

        #with postgres_engine.connect() as conn, conn.begin():
        pg_conn.execute(sql)

        sys.stdout.write('Successfully imported from:')

        for csv_path in glob(os.path.join(data_dir, '*_checked.csv')):
            table_name = os.path.basename(csv_path).replace('_checked.csv', '')

            # Because access can't handle datetimes in the default SQL format, it had to be converted to something Access could handle. So now, make it a datetime again
            df = pd.read_csv(csv_path, parse_dates=['datetime'])

            # get sqlite dtypes and convert data back as necessary since Access annoyingly converts bools to
            #   integers
            with sqlite_engine.connect() as conn, conn.begin():
                sqlite_data = pd.read_sql_table(table_name, conn)

            df = clean_app_data(df, sqlite_data, table_name, postgres_engine)

            if len(df):
                #with postgres_engine.connect() as pg_conn, pg_conn.begin():
                postgres_columns = pd.read_sql("SELECT column_name FROM information_schema.columns "
                                               "WHERE table_name = '{}' AND table_schema = 'public';"
                                               .format(table_name), pg_conn) \
                    .squeeze()\
                    .tolist()

                df.drop([c for c in df if c not in postgres_columns], axis=1, inplace=True)

                df.to_sql(table_name, pg_conn, if_exists='append', index=False)
                sys.stdout.write('\n\t-%s' % table_name)

    # Update the imported column
    try:
        with sqlite_engine.connect() as conn, conn.begin():
            session_columns = pd.read_sql_table('sessions', conn).columns
        if 'imported' not in session_columns:
            sqlite_engine.execute("ALTER TABLE sessions ADD COLUMN imported INTEGER;")
        sqlite_engine.execute("UPDATE sessions SET imported = 1;")

    except:
        warnings.warn("Failed to update 'imported' field in the data from the app. If you try to run this script again,"
                      "it will not warn you that these data have already been uploaded.")

    # Copy the sqlite db to the archive
    if not os.path.isdir(archive_dir):
        try:
            os.mkdir(archive_dir)
            #shutil.copy(sqlite_path, archive_dir)
        except:
            pass
    if data_files:
        for path in data_files.split(';'):
            shutil.copy(path, archive_dir)
    else:
        shutil.copy(sqlite_path, archive_dir)

    # Clean up the text files and temporary dir created by validate_app_data.py
    try:
        shutil.rmtree(data_dir)
    except:
        pass


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))