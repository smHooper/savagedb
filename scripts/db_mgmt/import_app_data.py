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
from validate_app_data import LOOKUP_FIELDS

# SQLite doesn't have a boolean datatype (they're stored as int) so
BOOLEAN_FIELDS = {'buses': ['is_training']}


def replace_lookup_values(data, engine, lookup_params):

    lookup_values = get_lookup_table(engine, lookup_params.lookup_table, lookup_params.lookup_value,
                                     lookup_params.lookup_index)
    data.replace({lookup_params.data_field: lookup_values}, inplace=True)

    return data



def main(data_dir, sqlite_path, connection_txt, archive_dir=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    postgres_engine = connect_db(connection_txt)
    sqlite_engine = create_engine("sqlite:///" + sqlite_path)

    for csv_path in glob(os.path.join(data_dir, '*_checked.csv')):
        table_name = os.path.basename(csv_path).replace('_checked.csv', '')

        # Because access can't handle datetimes in the default SQL format, it had to be converted to something Access could handle. So now, make it a datetime again
        df = pd.read_csv(csv_path, parse_dates=['datetime'])

        # get sqlite dtypes and convert data back as necessary since Access annoyingly converts bools to
        #   integers
        with sqlite_engine.connect() as conn, conn.begin():
            sqlite_data = pd.read_sql_table(table_name, conn)

        for c in df.columns:
            if c in sqlite_data.columns:
                dtype = sqlite_data[c].dtype
                if table_name in BOOLEAN_FIELDS:
                    if c in BOOLEAN_FIELDS[table_name]:
                        dtype = bool
                df[c] = df[c].astype(dtype)

        if 'destination' in df.columns:
            destination_lookup_params = pd.Series({'data_table': table_name, 'data_field': 'destination',
                                                   'lookup_table': 'destination_codes', 'lookup_index': 'code',
                                                   'lookup_value': 'name'})
            df = replace_lookup_values(df, postgres_engine, destination_lookup_params)
        if table_name in LOOKUP_FIELDS.index:
            df = replace_lookup_values(df, postgres_engine, LOOKUP_FIELDS.loc[table_name])

        if len(df):
            with postgres_engine.connect() as pg_conn, pg_conn.begin():
                postgres_columns = pd.read_sql("SELECT column_name FROM information_schema.columns "
                                               "WHERE table_name = '{}' AND table_schema = 'public';"
                                               .format(table_name), pg_conn) \
                    .squeeze()\
                    .tolist()

                df.drop([c for c in df if c not in postgres_columns] + ['id'], axis=1, inplace=True)

                df.to_sql(table_name, pg_conn, if_exists='append', index=False)

    # Update the imported column
    try:
        with sqlite_engine.connect() as conn, conn.begin():
            session_columns = pd.read_sql_table('sessions', conn, index_col='id').columns
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
            shutil.copy(sqlite_path, archive_dir)
        except:
            pass
    shutil.copy(sqlite_path, archive_dir)#'''

    # Clean up the text files and temporary dir created by validate_app_data.py
    try:
        shutil.rmtree(data_dir)
    except:
        pass


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))