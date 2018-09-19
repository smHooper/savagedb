import os
import fnmatch
import pandas as pd
import sys

START_YEAR = 1997
END_YEAR = 2017
DROP_DUPLICATES =  ['bluepermit_codes',
                    'bus_codes',
                    'codenames',
                    'datadates',
                    'destination_codes',
                    'employees',
                    'gmp',
                    'gmpnames',
                    'greenstudy',
                    'greenstudytp',
                    'greenstudywg',
                    'nonbus_codes',
                    'researcher',
                    'rightofway_codes',
                    'row_max']


def get_dtypes(df):

    # datetimes have to be parsed separately, so just get those first
    datetimes = df.index[(df.values == 'datetime64[ns]').any(axis=1)].tolist()

    # get anything that's an object (i.e., str)
    dtypes = {}
    for field in df.index[(df.values == 'object').any(axis=1)]:
        if field not in datetimes:
            dtypes[field] = object

    # all others can be interpreted by the pandas parser
    return dtypes, datetimes


def parse_dates(x):
    if isinstance(x, str):
        return pd.datetime.strptime(x, '%Y-%m-%d %H:%M:%S')
    else:
        return pd.to_datetime('1899-12-30 00:00:00')


def main(root_dir, out_dir=None, drop_duplicates=True):

    if out_dir is None:
        out_dir = os.path.join(root_dir, 'merged_tables')
    if not os.path.isdir(out_dir):
        os.mkdir(out_dir)

    tables = []
    for root, dirs, files in os.walk(root_dir):
        tables.extend([csv for csv in fnmatch.filter(files, '*.csv')])
    tables = set(tables)

    year_strs = [str(y) for y in range(START_YEAR, END_YEAR + 1)]
    for csv in tables:
        print '\nMerging %s...' % csv.replace('.csv','')
        if '_codes' in csv:
            dtypes_txt = os.path.join(os.path.join(root_dir, 'dtypes'), 'codenames.csv')
        else:
            dtypes_txt = os.path.join(os.path.join(root_dir, 'dtypes'), csv)
        try:
            dtypes = pd.read_csv(dtypes_txt, index_col='field')
        except:
            import pdb; pdb.set_trace()
        strings, datetimes = get_dtypes(dtypes)
        df = pd.DataFrame()
        for year in year_strs:
            this_path = os.path.join(os.path.join(root_dir, year), csv)
            if not os.path.isfile(this_path):
                continue
            try:
                this_df = pd.read_csv(this_path, dtype=strings, parse_dates=datetimes, infer_datetime_format=True)
            except:
                import pdb; pdb.set_trace()
            try:
                df = pd.concat([df, this_df])
            except:
                import pdb; pdb.set_trace()

        if drop_duplicates and csv.replace('.csv','') in DROP_DUPLICATES:
            try:
                df.drop_duplicates(inplace=True)
            except:
                import pdb;
                pdb.set_trace()
        out_txt = os.path.join(out_dir, csv)
        df.to_csv(out_txt, index=False)


if __name__ == '__main__':

    sys.exit(main(*sys.argv[1:]))


