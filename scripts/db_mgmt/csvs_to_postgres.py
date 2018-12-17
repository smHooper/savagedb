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
import warnings
from glob import glob
import sqlalchemy
from sqlalchemy import create_engine
from sqlalchemy import types as sqltypes
import pandas as pd
import numpy as np


DTYPES = {np.int64: sqltypes.BigInteger,
          np.float64: sqltypes.Float,
          bool: sqltypes.Boolean,
          object: sqltypes.String,
          }

def main(search_dir, db_name=None, password=None, username='postgres', ip_address='localhost', port=5432, connection_txt=None, primary_key='id', foreign_key=None, convert_datetimes=True):

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

    if type(primary_key) == str:
        if ',' in primary_key:
            try:
                primary_key = {k.strip(): v.strip() for k, v in [item.strip().split(':') for item in primary_key.split(',')]}
            except:
                raise ValueError('primary_key format not understood: %s. It must be either a single string or a '
                                 'comma-separated string where each item is table_name: primary_key_col' % primary_key)
    elif not type(primary_key) == dict:
        raise ValueError('primary_key must either be string or dict. %s given instead' % type(primary_key))

    tables = []
    for csv in files:
        basename = os.path.basename(csv)
        print 'Importing %s...' % basename
        df = pd.read_csv(csv)
        table_name = basename.replace('.csv', '')
        with engine.connect() as conn, conn.begin():
            df.to_sql(table_name, conn, if_exists='append')

            # If a dictionary of primary keys was given, try to get the key for this table. If it doesn't exists,
            #   just us 'id'
            if hasattr(primary_key, 'keys'):
                if table_name in primary_key:
                    this_primary_key = primary_key[table_name]
                else:
                    this_primary_key = 'id'
            # If it isn't a dictionary, use the string given
            else:
                this_primary_key = primary_key

           # If this primary key already exists, try to add the pkey constraint to the given column
            if this_primary_key in df.columns:
                sql = ''
                # If the pkey is 'id', drop the column so it can be autoincrementing
                if this_primary_key == 'id':
                    sql = "ALTER TABLE {table_name} DROP COLUMN id; " \
                          "ALTER TABLE {table_name} ADD COLUMN id SERIAL PRIMARY KEY"\
                            .format(table_name=table_name)
                # Otherwise, don't make the pkey auto-incrementing, but create an auto-incrementing 'id' field that isn't
                #   a primary key
                else:
                    sql += 'ALTER TABLE {table_name} ADD PRIMARY KEY ({primary_key});' \
                           'ALTER TABLE {table_name} ADD COLUMN id SERIAL;'\
                        .format(table_name=table_name, primary_key=this_primary_key)
            # If it doesn't exist, make it auto-incrementing
            else:
                sql = 'ALTER TABLE {table_name} ADD COLUMN {primary_key} SERIAL PRIMARY KEY'.format(
                    table_name=table_name, primary_key=this_primary_key)
            try:
                conn.execute(sql)
            except sqlalchemy.exc.SQLAlchemyError as e:
                warnings.warn("Error setting primary key {primary_key} in table {table_name} because {message}"
                              .format(primary_key=this_primary_key, table_name=table_name, message=e.message))
            if convert_datetimes:
                sql = ''
                for date_col in [c for c in df.columns if c.endswith('date')]:
                    sql += 'ALTER TABLE {table_name}' \
                          ' ALTER COLUMN {date_col} SET DATA TYPE date' \
                          ' USING {date_col}::date; '.format(table_name=table_name, date_col=date_col)
                for time_col in [c for c in df.columns if c.endswith('time')]:
                    sql += 'ALTER TABLE {table_name}' \
                          ' ALTER COLUMN {time_col} SET DATA TYPE timestamp' \
                          ' USING {time_col}::timestamp; '.format(table_name=table_name, time_col=time_col)
                if sql: # will be an empty string if no tables are datetimes
                    conn.execute(sql)
            tables.append(table_name)

    for table_name in tables:
        # Drop the "index" column that gets automatically created when you add the primary key index
        sql = "ALTER TABLE {table_name} DROP COLUMN IF EXISTS index;".format(table_name=table_name)
        with engine.connect() as conn, conn.begin():
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