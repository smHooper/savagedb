'''
Import all csvs found in a specified directory into a specified (and existing) postgres DB

Usage:
    csvs_to_postgres.py <search_dir> (--db_name=<str> --password=<str> | --connection_txt=<str>) [--username=<str>] [--ip_address=<str>] [--port=<str>] [--primary_key=<str>] [--convert_datetimes=<bool>]
    csvs_to_postgres.py -h | --help

Examples:
    python csvs_to_postgres.py "C:\Users\shooper\proj\savagedb\db\exported_tables" --search_dir="C:\Users\shooper\proj\savagedb\db\original"

Options:
    -h --help                   Show this screen
    --search_dir=<str>          Path to directory to search to for csv files.
    --db_name=<str>             Name of the database to connect to. If connection_txt is not specified, both db_name and password must be given.
    --password=<str>            Password for the user specified. If connection_txt is not specified, both db_name and password must be given. Default user is 'postgres'
    --connection_txt=<str>      Full path to a text file with connection info. This parameter must be given if db_name and password are not.
    --username=<str>            Username to login with. Default is 'postgres'
    --ip_address=<str>          IP address of the machine to connect to. Default is 'localhost'
    --port=<str>                Port to connect to. Default is '5432'
    --primary_key=<str>         Field to use for primary key for all tables (if it exists)
    --convert_datetimes=<bool>  If True, any field with a name ending in 'date' or 'time' will be coerced into 'date' or 'timestamp' data type, respectively
'''


import sys
import os
import docopt
import re
from glob import glob
from sqlalchemy import create_engine
from sqlalchemy import types as sqltypes
import pandas as pd
import numpy as np


DTYPES = {np.int64: sqltypes.BigInteger,
          np.float64: sqltypes.Float,
          bool: sqltypes.Boolean,
          object: sqltypes.String,
          }

def main(search_dir, db_name=None, password=None, username='postgres', ip_address='localhost', port=5432, connection_txt=None, primary_key='id', convert_datetimes=True):

    files = glob(os.path.join(search_dir, '*.csv'))
    if len(files) == 0:
        raise IOError('No files found in %s' % search_dir)

    if connection_txt:
        connection_info = {}
        # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
        connection_info = {}
        with open(connection_txt) as txt:
            for line in txt.readlines():
                if ';' not in line:
                    continue
                param_name, param_value = line.split(';')
                connection_info[param_name.strip()] = param_value.strip()

    else:
        connection_info = {'username': username,
                           'password': password,
                           'ip_address': ip_address,
                           'port': str(port),
                           'db_name': db_name}
    try:
        engine = create_engine( 'postgresql://{username}:{password}@{ip_address}:{port}/{db_name}'.format(**connection_info))
    except:
        message = '\n' + '\n\t'.join(['%s: %s' % (k, v) for k, v in connection_info.iteritems()])
        raise ValueError('could not establish connection with parameters:%s' % message)

    for csv in files:
        basename = os.path.basename(csv)
        print 'Importing %s...' % basename
        df = pd.read_csv(csv)
        table_name = basename.replace('.csv', '')
        with engine.connect() as conn, conn.begin():
            df.to_sql(table_name, conn, if_exists='append')
            if primary_key not in df.columns:
                sql = 'ALTER TABLE {table_name} ADD COLUMN {primary_key} SERIAL PRIMARY KEY'.format(
                    table_name=table_name, primary_key=primary_key)
                conn.execute(sql)

            if convert_datetimes:
                sql = ''#'ALTER TABLE %s' % table_name
                for date_col in [c for c in df.columns if c.endswith('date')]:
                    sql += 'ALTER TABLE {table_name}' \
                          ' ALTER COLUMN {date_col} SET DATA TYPE date' \
                          ' USING {date_col}::date; '.format(table_name=table_name, date_col=date_col)
                for time_col in [c for c in df.columns if c.endswith('time')]:
                    sql += 'ALTER TABLE {table_name}' \
                          ' ALTER COLUMN {time_col} SET DATA TYPE time' \
                          ' USING {time_col}::time; '.format(table_name=table_name, time_col=time_col)
                if sql: # will be an empty string if no tables are datetimes
                    conn.execute(sql)

            # Drop the "index" column that gets automatically created when you add the primary key index
            sql = "ALTER TABLE tt DROP COLUMN IF EXISTS {table_name};".format(table_name)
            conn.execute(sql)


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}
    
    if 'convert_datetimes' in args:
        if args['convert_datetimes'].lower() == 'false':
            args['convert_datetimes'] = False
            
    sys.exit(main(**args))