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
from datetime import datetime
import pandas as pd
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

    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
    engine = query.connect_db(connection_txt)

    # Get field names that don't contain unique IDs
    field_names = query.query_field_names(engine)

    # Initiate the log file
    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.flush()

    yearly_data = []
    for year in years:
        start_date = '%s-05-20 00:00:00' % year
        end_date = '%s-09-16 00:00:00' % year

        gmp_date_clause, _, _ = cvbt.get_gmp_date_clause(datetime(year, 5, 1), datetime(year, 9, 16))
        date_range = cvbt.get_date_range(start_date, end_date, summarize_by='month')
        output_fields = cvbt.get_output_field_names(date_range, 'month')

        # Query buses
        bus_names = {'VTS': ['Shuttle', 'Camper', 'Other'],#
                     'Tour': ['Kantishna Experience', 'Eielson Excursion', 'Tundra Wilderness Tour', 'Windows Into Wilderness']##,
                     }

        other_criteria = "is_training = ''false'' " + gmp_date_clause.replace("'", "''")
        bus_vehicles = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',
                                                        other_criteria=other_criteria, dissolve_names=bus_names,
                                                        field_names=field_names['buses'], summarize_by='month',
                                                        output_fields=output_fields, filter_fields=True)

        bus_passengers = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',                                                   other_criteria=other_criteria, dissolve_names=bus_names,
                                                        field_names=field_names['buses'], summarize_by='month',
                                                        output_fields=output_fields, filter_fields=True, summary_stat='SUM', value_field='n_passengers')
        bus_passengers.index = [ind + ' pax' for ind in bus_passengers.index]



        # Query training buses
        trn_names = {'JV training': [item for k, v in bus_names.iteritems() for item in v],
                     'Lodge bus training': ['Camp Denali/North Face Lodge', 'Kantishna Roadhouse', 'Denali Backcountry Lodge']}
        other_criteria = "is_training " + gmp_date_clause.replace("'", "''")
        trn_buses = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type',
                                                     other_criteria=other_criteria, dissolve_names=trn_names,
                                                     field_names=field_names['buses'], summarize_by='month',
                                                     output_fields=output_fields)

        # Query nps_approved
        approved_vehicles = query.crosstab_query_by_datetime(engine, 'nps_approved', start_date, end_date, 'approved_type',
                                                             other_criteria="destination <> ''Primrose/Mile 17'' " + gmp_date_clause.replace("'", "''"),
                                                             field_names=field_names['nps_approved'], summarize_by='month',
                                                             output_fields=output_fields)

        # Get concessionaire (i.e., JV) trips to Primrose separately because it's not included in the GMP count
        other_criteria = "destination = ''Primrose/Mile 17'' AND approved_type = ''Concessionaire'' "
        approved_vehicles_primrose = query.crosstab_query_by_datetime(engine, 'nps_approved', start_date, end_date, 'approved_type',
                                                             other_criteria=other_criteria + gmp_date_clause.replace("'", "''"),
                                                             field_names=field_names['nps_approved'], summarize_by='month',
                                                             output_fields=output_fields)
        approved_vehicles_primrose.index = ['JV (Primrose)']

        # Query all other vehicle types with a regular GROUP BY query
        simple_counts = []
        other_criteria = "destination <> 'Primrose/Mile 17' " + gmp_date_clause
        for table_name in SIMPLE_COUNT_QUERIES:
            counts = query.simple_query_by_datetime(engine, table_name, field_names=field_names[table_name], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields)
            simple_counts.append(counts)
        simple_counts = pd.concat(simple_counts, sort=False)

        # Get tek and accessibility passengers and number of cyclists
        accessibility_passengers = query.simple_query_by_datetime(engine, 'accessibility', field_names=field_names['accessibility'], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields, summary_field='n_passengers', summary_stat='SUM')

        accessibility_passengers.index = [PRINT_NAMES['accessibility'] + ' pax']
        tek_passengers = query.simple_query_by_datetime(engine, 'tek_campers', field_names=field_names['tek_campers'], other_criteria=other_criteria, summarize_by='month', output_fields=output_fields, summary_field='n_passengers', summary_stat='SUM')

        tek_passengers.index = [PRINT_NAMES['tek_campers'] + ' pax']
        cyclists = query.simple_query_by_datetime(engine, 'cyclists', field_names=field_names['cyclists'],
                                                        other_criteria=other_criteria, summarize_by='month',
                                                        output_fields=output_fields, summary_field='n_passengers',
                                                        summary_stat='SUM')
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
             all_data.loc[:, (year, 'total')] * 100)\
                .round(1)
    all_data = all_data.fillna(0)

    if not out_csv:
        out_basename = 'ridership_%s_%s.csv' % (years[0], years[-1]) if len(years) > 1 else 'ridership_%s.csv' % years[0]
        out_csv = os.path.join(out_dir, out_basename)
    all_data.to_csv(out_csv)

    print '\nCSV written to: %s' % out_csv


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    sys.exit(main(**args))