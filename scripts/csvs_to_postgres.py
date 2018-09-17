'''
Import all csvs found in a specified directory into a specified (and existing) postgres DB
'''


import sys, os
from glob import glob
from sqlalchemy import create_engine
import pandas as pd


def main(search_dir, db_name, password, username='postgres', ip_address='localhost', port=5432):

    files = glob(os.path.join(search_dir, '*.csv'))
    if len(files) == 0:
        raise IOError('No files found in %s' % search_dir)

    format_dict = {'username': username,
                   'password': password,
                   'ip_address': ip_address,
                   'port': str(port),
                   'db_name': db_name}
    engine = create_engine( 'postgresql://{username}:{password}@{ip_address}:{port}/{db_name}'.format(**format_dict))

    for csv in files:
        basename = os.path.basename(csv)
        print 'Importing %s...' % basename
        df = pd.read_csv(csv)
        table_name = basename.replace('.csv', '')
        with engine.connect() as conn, conn.begin():
            df.to_sql(table_name, conn)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))