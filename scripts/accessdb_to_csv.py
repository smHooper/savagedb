'''
Export tables from 1 or more Access databases.

Usage:
    acceessdb_to_csv.py <out_dir> (--db_path=<str> | --search_dir=<str>) [--year=<str>] [--table_names=<str> | --exclude_tables=<str>]
    acceessdb_to_csv.py -h | --help

Options:
    -h --help               Show this screen
    --db_path=<str>         Path of a DB file. If not specified, search_dir must be given
    --search_dir=<str>      Path to directory to search to for DB files. If not specified, db_path must be given.
    --year=<str>            If specified, all CSVs will be written to out_dir/year
    --table_names=<str>     Comma-separated list of tables to export. If specified, only these tables will be exported. If not specified, exclude_tables must be given.
    --exclude_tables=<str>  Comma-separated list of tables to exclude from exports. If table_names is specified, this option is ignored.
'''

import os
import sys
import re
import glob
import warnings
import docopt
import pyodbc
import pandas as pd
import xarray as xr

pyodbc.pooling = False #Truly close connections when calling connection.close() (probably unnecessary for Access)

EXCLUDED_TABLES = ['Paste Errors',
                   'Notes',
                   'time',
                   'Info',
                   'Switchboard Items']


def export_tables(db_path, out_dir, table_names=None, replace_char='_'):
    """
    Export all true tables from Access database at db_path as CSVs to out_dir. Only export tables in table_names if
    :param db_path: full path to .mdb or .accdb file
    :param out_dir: directory to write csv to
    :param table_names: list of tables to export
    :param replace_char: string character for substituting special characters in field and table names
    :return: None
    """
    conn = pyodbc.connect(r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};'
                          r'DBQ=%s' % db_path)
    cursor = conn.cursor()

    # if table names not specified, get all table names
    if not table_names:
        table_names = [t.table_name for t in cursor.tables() if t.table_type == 'TABLE']

    dtypes = {}
    for name in table_names:
        try:
            df = pd.read_sql('SELECT * FROM "%s"' % name, conn)
        except:  # could throw DatabaseError if table name not in DB (could happen if table_names specified)
            warnings.warn('Table %s does not exist in %s' % (name, db_path), RuntimeWarning)

        # Replace special characters in columns and table name with '_'
        df.columns = [re.sub('[^\w0-9a-zA-Z]+', replace_char, c.lower()) for c in df.columns]
        out_name = re.sub('[^\w0-9a-zA-Z]+', replace_char, name.lower())
        out_txt = os.path.join(out_dir, out_name + '.csv')
        df.to_csv(out_txt, index=False, encoding='utf-8')
        '''if out_name == 'bustraffic':
            import pdb;
            pdb.set_trace()#'''
        # Get the datatype for each column
        dtypes[out_name] = df.dtypes

    # Close connection
    cursor.close()
    conn.close()
    del cursor

    return dtypes


def main(out_dir, db_path=None, search_dir=None, year=None, table_names=None, exclude_tables=True):

    # check to see if paths exist
    if db_path is not None:
        if not os.path.exists(db_path):
            raise IOError('Database path does not exist: %s' % db_path)
        db_paths = [db_path]  # make sure it's iterable for the for loop
    elif search_dir is not None:
        db_paths = glob.glob(os.path.join(search_dir, '*.mdb'))
    else:
        raise RuntimeError('Neither a path nor search directory specified')

    if not os.path.isdir(out_dir):
        os.mkdir(out_dir)

    # Get table names or the tables to exclude
    if table_names:
        table_names = [t.strip() for t in table_names.split(',')]
        exclude_tables = [] #if tables were given, safe to assume none of them should be excluded
    if exclude_tables:
        if type(exclude_tables) == str:
            exclude_tables = [t.strip() for t in exclude_tables.split(',')]
        else:
            exclude_tables = EXCLUDED_TABLES
    else:
        exclude_tables = []

    used_tables = []
    dtypes = {}
    yr = year #Get the starting value for year to check if year is None
    for path in db_paths:
        this_out_dir = out_dir  # if year is None, set working output dir to out_dir
        # if year isn't specified, try to infer it from the DB name
        matched_year = re.findall('\d\d\d\d', os.path.basename(path))
        if len(matched_year) == 1 and yr is None:
            year = matched_year[0]  #findall returns a list, so get the only item
            this_out_dir = os.path.join(this_out_dir, year)
        if not os.path.isdir(this_out_dir):
            os.mkdir(this_out_dir)

        # Get table names so the right ones can be excluded
        conn = pyodbc.connect(r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};'
                              r'DBQ=%s' % path)
        cursor = conn.cursor()
        table_names = [t.table_name for t in cursor.tables()# if t.table_type == 'TABLE' in table_names and t.table_name not in exclude_tables]
                       if t.table_type == 'TABLE' and
                       t.table_name not in exclude_tables]
        cursor.close()
        conn.close()
        del cursor

        these_dtypes = export_tables(path, this_out_dir, table_names=table_names)
        if year:
            dtypes[year] = these_dtypes
            used_tables.extend(these_dtypes.keys())
        print 'Tables exported to', this_out_dir

    # Get the datatypes for each field per database
    dtypes = pd.Panel(dtypes)#will be deprecated in future. Change to xarray
    dtype_out_dir = os.path.join(out_dir, 'dtypes')
    if not os.path.isdir(dtype_out_dir):
        os.mkdir(dtype_out_dir)
    for tname in set(used_tables):
        table_dtypes = dtypes.loc[:, :, tname] # get all dtypes for this table for all DBs
        table_dtypes = table_dtypes.loc[~table_dtypes.isnull().all(axis=1)] # get rid of records for field not in this table
        table_dtypes.index.name = 'table'
        table_dtypes.to_csv(os.path.join(dtype_out_dir, tname + '.csv'))


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    if 'exclude_tables' in args:
        if args['exclude_tables'].lower() == 'false':
            args['exclude_tables'] = False

    sys.exit(main(**args))