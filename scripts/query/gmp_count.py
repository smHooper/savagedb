'''
Query summary stats for one or more years from the Savage Box DB

Usage:
    gmp_count.py <connection_txt> --years=<str> (--out_dir=<str> | --out_csv=<str>)
    gmp_count.py -h | --help

Examples:
    python gmp_count.py ..\..\connection_info.txt --out_dir=C:\users\shooper\desktop --years="2012,2016"
    python gmp_count.py ..\..\connection_info.txt --out_csv=C:\users\shooper\desktop\ridership.csv --years="2013-2016"

Required parameters:
    connection_txt      text file containing information to connect to the DB. Each line
                        in the text file must be in the form 'variable_name; variable_value.'
                        Required variables: username, password, ip_address, port, db_name

Options:
    -h --help           Show this screen
    --years=<str>       Either a single 4-digit year, a list of years separated by commas, or a range given in the form <start_year>-<end_year>
    --out_dir=<str>     path to the directory to store the output text file. If given, output text file will be saved to a file named ridership_<min_year>_<max_year>.csv will be written. If out_dir is not specified, out_csv must be given
    --out_csv=<str>     path to output text file. If out_csv is not specified, out_dir must be given

'''


import os, sys
import re
import subprocess
from datetime import datetime
import pandas as pd
import numpy as np
import docopt

import query
import count_vehicles_by_type as cvbt

# table_name: print_name
SIMPLE_COUNT_QUERIES = {'tek_campers',
                        'photographers',
                        'accessibility',
                        'nps_vehicles',
                        'subsistence',
                        'inholders',
                        'nps_contractors',
                        'employee_vehicles'
                        }
PRINT_NAMES = {'tek_campers':                   'Tek campers',
               'Tek campers pax':               'Tek camper pax',
               'employee_vehicles':             'Employees',
               'photographers':                 'Prophos',
               'accessibility':                 'Accessibility',
               'nps_vehicles':                  'NPS',
               'subsistence':                   'Subsistence',
               'inholders':                     'Inholders',
               'nps_contractors':               'Contractors',
               'Denali Backcountry Lodge':      'DBL buses',
               'Denali Backcountry Lodge pax':  'DBL pax',
               'Denali Natural History Tour':   'DNHT',
               'Denali Natural History Tour pax': 'DNHT pax',
               'Kantishna Roadhouse':           'KRH buses',
               'Kantishna Roadhouse pax':       'KRH pax',
               'Camp Denali/North Face Lodge':        'CD-NF buses',
               'Camp Denali/North Face Lodge pax':    'CD-NF pax',
               'Researcher':                    'Researchers',
               'Concessionaire':                'JV',
               'Concessionaire (Primrose)':     'JV (Primrose)',
               'cyclists':                      'Cyclists'
               }
SORT_ORDER = ['Tour',
              'Tour pax',
              'VTS',
              'VTS pax',
              'JV training',
              'CD-NF buses',
              'CD-NF pax',
              'DBL buses',
              'DBL pax',
              'KRH buses',
              'KRH pax',
              'Lodge bus training',
              'Inholders',
              'Subsistence',
              'Tek campers',
              'Tek camper pax',
              'Prophos',
              'Accessibility',
              'Accessibility pax',
              'Researchers',
              'Education',
              'Employees',
              'JV',
              'NPS',
              'Other',
              'DNHT',
              'DNHT pax',
              'JV (Primrose)',
              'Contractors',
              'Cyclists']


def main(connection_txt, years=None, out_dir=None, out_csv=None):

    if not (out_dir or out_csv):
        raise ValueError('Either a valid out_dir or out_csv must be given')

    # If none given, just used the current year
    if not years:
        years = [datetime.now().year]

    # If passed from the command line, it will by in the form 'year1, year2'
    elif ',' in years:
        years = [int(y.strip()) for y in years.split(',')]
    # or year_start-year_end
    elif '-' in years:
        year_start, year_end = [int(y.strip()) for y in years.split('-')]
        years = range(year_start, year_end + 1)
    elif len(years) == 4:
        years = [int(years)]
    else:
        raise ValueError('years must be in the form "YYYY", "year1, year2, ...", or "year_start-year_end". Years given were %s' % years)

    if not out_csv:
        out_basename = 'gmp_vehicle_count_%s_%s.csv' % (years[0], years[-1]) if len(years) > 1 else 'gmp_vehicle_count_%s.csv' % years[0]
        out_csv = os.path.join(out_dir, out_basename)

    # Try to open the file to make sure it's not already open and therefore locked
    try:
        f = open(out_csv, 'w')
        f.close()
    except IOError as e:
        if e.errno == os.errno.EACCES:
            raise IOError('Permission to access the output file %s was denied. This is likely because the file is currently open. Please close the file and re-run the script.' % out_csv)
        # Not a permission error.
        raise

    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
    engine = query.connect_db(connection_txt)

    # Get field names that don't contain unique IDs
    field_names = query.query_field_names(engine)

    # Initiate the log file
    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    yearly_data = []
    sql_statements = []
    for year in years:
        start_date = '%s-05-20 00:00:00' % year
        end_date = '%s-09-16 00:00:00' % year

        gmp_starts, gmp_ends = cvbt.get_gmp_dates(datetime(year, 5, 1), datetime(year, 9, 16))
        btw_stmts = []
        for gmp_start, gmp_end in zip(gmp_starts, gmp_ends):
            btw_stmts.append("(datetime::date BETWEEN '{start}' AND '{end}') "
                             .format(start=gmp_start.strftime('%Y-%m-%d'),
                                     end=gmp_end.strftime('%Y-%m-%d'))
                             )
        gmp_date_clause = ' AND (%s) ' % ('OR '.join(btw_stmts))

        #gmp_date_clause, _, _ = cvbt.get_gmp_date_clause(datetime(year, 5, 1), datetime(year, 9, 16))
        date_range = cvbt.get_date_range(start_date, end_date, summarize_by='month')
        output_fields = cvbt.get_output_field_names(date_range, 'month')

        # Query buses
        bus_names = {'VTS': ['SHU', 'CMP', 'OTH', 'NUL'],#
                     'Tour': ['KXP', 'EXC', 'TWT', 'WIW']##,
                     }
        other_criteria = "is_training = ''false'' " + gmp_date_clause.replace("'", "''")
        # All non-training buses except DNHTs. Do this separately so I can exclude buses going to Primrose
        bus_vehicles, sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',
                                                        other_criteria=other_criteria + " AND bus_type <> ''DNH'' AND destination <> ''PRM''",
                                                             dissolve_names=bus_names,
                                                        field_names=field_names['buses'], summarize_by='month',
                                                        output_fields=output_fields, filter_fields=True, return_sql=True)
        sql_statements.append(sql)
        # Just non-training DNHTs
        dnhts, sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',
                                                        other_criteria=other_criteria + " AND bus_type = ''DNH''",
                                                        field_names=field_names['buses'], summarize_by='month',
                                                        output_fields=output_fields, filter_fields=True, return_sql=True)
        sql_statements.append(sql)
        bus_vehicles = bus_vehicles.append(dnhts)

        # Rename lodge bus codes to use actual name
        bus_codes = query.get_lookup_table(engine, 'bus_codes')
        #del bus_codes['NUL'] # don't count buses without a type
        bus_vehicles.rename(index=bus_codes, inplace=True)

        # Query bus passengers
        bus_passengers, sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',                                                   other_criteria=other_criteria, dissolve_names=bus_names,
                                                        field_names=field_names['buses'], summarize_by='month',
                                                        output_fields=output_fields, filter_fields=True, summary_stat='SUM', summary_field='n_passengers', return_sql=True)
        sql_statements.append(sql)
        # Again, rename lodge bus codes to use actual names
        bus_passengers.rename(index=bus_codes, inplace=True)
        bus_passengers.index = [ind + ' pax' for ind in bus_passengers.index]


        # Query training buses
        trn_names = {'JV training': [item for k, v in bus_names.iteritems() for item in v],
                     'Lodge bus training': ['CDN', 'KRH', 'DBL']}
        other_criteria = "is_training " + gmp_date_clause.replace("'", "''")
        trn_buses, sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',
                                                     other_criteria=other_criteria, dissolve_names=trn_names,
                                                     field_names=field_names['buses'], summarize_by='month',
                                                     output_fields=output_fields, return_sql=True)
        sql_statements.append(sql)

        # Query nps_approved
        primrose_stmt = " AND destination <> 'PRM' "
        other_criteria = (gmp_date_clause + primrose_stmt).replace("'", "''")
        approved_vehicles, sql = query.crosstab_query_by_datetime(engine, 'nps_approved', start_date, end_date, 'approved_type',
                                                             other_criteria=other_criteria,
                                                             field_names=field_names['nps_approved'], summarize_by='month',
                                                             output_fields=output_fields, return_sql=True,
                                                                  dissolve_names= {'Other': ['OTH', 'NUL']})
        approved_codes = query.get_lookup_table(engine, 'nps_approved_codes')
        approved_vehicles.rename(index=approved_codes, inplace=True)
        sql_statements.append(sql)

        # Get concessionaire (i.e., JV) trips to Primrose separately because it's not included in the GMP count
        other_criteria = "destination = ''PRM'' AND approved_type = ''CON'' "
        approved_vehicles_primrose, sql = query.crosstab_query_by_datetime(engine, 'nps_approved', start_date, end_date, 'approved_type',
                                                             other_criteria=other_criteria + gmp_date_clause.replace("'", "''"),
                                                             field_names=field_names['nps_approved'], summarize_by='month',
                                                             output_fields=output_fields, return_sql=True)
        sql_statements.append(sql)
        if len(approved_vehicles_primrose) > 0:
            approved_vehicles_primrose.index = ['JV (Primrose)']

        # Rename Nulls to other.
        approved_vehicles.rename(index={'Null': 'Other'}, inplace=True)
        approved_vehicles = approved_vehicles.groupby(by=approved_vehicles.index).sum()#consilidate 2 'Other'

        # Query all other vehicle types with a regular GROUP BY query
        simple_counts = []
        other_criteria = (gmp_date_clause + primrose_stmt).lstrip('AND ')
        for table_name in SIMPLE_COUNT_QUERIES:
            counts, sql = query.simple_query_by_datetime(engine, table_name, field_names=field_names[table_name], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields, return_sql=True)
            simple_counts.append(counts)
            sql_statements.append(sql)
        simple_counts = pd.concat(simple_counts, sort=False)

        # Get tek and accessibility passengers and number of cyclists
        accessibility_passengers, sql = query.simple_query_by_datetime(engine, 'accessibility', field_names=field_names['accessibility'], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields, summary_field='n_passengers', summary_stat='SUM', return_sql=True)
        sql_statements.append(sql)
        if len(accessibility_passengers) > 0:
            accessibility_passengers.index = [PRINT_NAMES['accessibility'] + ' pax']

        tek_passengers, sql = query.simple_query_by_datetime(engine, 'tek_campers', field_names=field_names['tek_campers'], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields, summary_field='n_passengers', summary_stat='SUM', return_sql=True)
        if len(tek_passengers) > 0:
            tek_passengers.index = [PRINT_NAMES['tek_campers'] + ' pax']
        sql_statements.append(sql)

        cyclists, sql = query.simple_query_by_datetime(engine, 'cyclists', field_names=field_names['cyclists'],
                                                        other_criteria=other_criteria, summarize_by='month',
                                                        output_fields=output_fields, summary_field='n_passengers',
                                                        summary_stat='SUM', return_sql=True)
        sql_statements.append(sql)
        if len(cyclists) > 0:
            cyclists.index = [PRINT_NAMES['cyclists']]

        all_data = pd.concat([bus_vehicles,
                             bus_passengers,
                             trn_buses,
                             approved_vehicles,
                             approved_vehicles_primrose,
                             simple_counts,
                             accessibility_passengers,
                             tek_passengers,
                              cyclists],
                             sort=False)


        all_data.columns = [datetime.strftime(datetime.strptime(c, '_%Y_%m'), '%b') if c != 'total' else c for c in all_data.columns]

        # Make sure all rows have print-worthy names and set the order of rows and cols
        def replace(x, d):
            return d[x] if x in d else x
        all_data.index = all_data.index.map(lambda x: replace(x, PRINT_NAMES))

        if 'NUL' in all_data.index.tolist(): all_data.drop('NUL', inplace=True)
        all_data = all_data.reindex(index=SORT_ORDER, columns=['May', 'Jun', 'Jul', 'Aug', 'Sep', 'total']).fillna(0)

        # Set a multiindex for GMP stats (rows)
        gmp_rows = all_data.index[:-5]
        all_data.index = [['GMP'] * len(gmp_rows) + ['Non-GMP'] * (len(all_data) - len(gmp_rows)), all_data.index]

        # Calculate totals
        pax_inds = [ind for ind in all_data.loc['GMP'].index.get_level_values(0) if 'pax' in ind]
        vehicle_inds = [ind for ind in all_data.loc['GMP'].index.get_level_values(0) if 'pax' not in ind]
        all_data.loc[('Totals', 'GMP vehicles'), :] = all_data.loc[('GMP', vehicle_inds), :].sum(axis=0)
        all_data.loc[('Totals', 'GMP pax'), :] = all_data.loc[('GMP', pax_inds), :].sum(axis=0)
        all_data.columns = [[year] * len(all_data.columns), all_data.columns]
        yearly_data.append(all_data)

    # Combine all years into one df and calculate % change if
    all_data = pd.concat(yearly_data, axis=1)
    last_year = years[-1]
    for year in years[:-1]:
        all_data.loc[:, ('total_pct_change', 'from_%s' % year)] = \
            ((all_data.loc[:, (last_year, 'total')] - all_data.loc[:, (year, 'total')]) /
             all_data.loc[:, (year, 'total')] * 100) \
                .replace([np.inf, -np.inf], np.nan)\
                .fillna(0)\
                .round(1)
    #all_data = all_data.fillna(0)

    all_data.to_csv(out_csv)

    out_sql_txt = out_csv.replace('.csv', '_sql.txt')
    break_str = '#' * 100
    with open(out_sql_txt, 'w') as f:
        for stmt in sql_statements:
            f.write(stmt + '\n\n%s\n\n' % break_str)
        f.write('\n\n\n')

    print '\nCSV written to: %s' % out_csv


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    sys.exit(main(**args))