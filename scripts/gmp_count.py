import os, sys
from datetime import datetime
from sqlalchemy import create_engine
import pandas as pd


def simnple_query(engine, table_name, year, summary_field='obs_date', summary_stat='COUNT', other_criteria=''):

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    modify_criteria = other_criteria.strip() and \
                      not (other_criteria.lower().strip().startswith('and ') or
                           other_criteria.lower().strip().startswith('or '))
    if modify_criteria:
        other_criteria = 'AND ' + other_criteria

    sql = 'SELECT ' \
          '   extract(month FROM obs_date) AS month, ' \
          '   {summary_stat}({summary_field}) AS {table_name} ' \
          'FROM (SELECT DISTINCT * FROM {table_name}) AS {table_name} ' \
          'WHERE obs_date BETWEEN \'{year}-05-28\' AND \'{year}-09-15\' ' \
          '{other_criteria} ' \
          'GROUP BY extract(month FROM obs_date);' \
        .format(**{'summary_stat': summary_stat,
                   'summary_field': summary_field,
                   'table_name': table_name,
                   'year': str(year),
                   'other_criteria': other_criteria}
                )
    # Execute query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # postgres won't capitalize aliases in result so make sure print_name is set
    #counts.rename(columns={table_name: print_name}, inplace=True)

    # transform data so months are columns and the only row is the thing we're counting
    counts = counts.set_index('month').T
    counts.rename(columns={5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep'}, inplace=True)
    counts.index.name = 'vehicle_type'

    counts['total'] = counts.sum(axis=1)

    return counts


def crosstab_query(engine, table_name, pivot_field, value_field, year, summary_stat='COUNT', dissolve_names={}, other_criteria=''):

    # Make sure other_criteria is prepended with AND unless the string is null
    if other_criteria.strip() and not other_criteria.lower().strip().startswith('and '):
        other_criteria = 'AND ' + other_criteria

    sql = 'SELECT * FROM crosstab(' \
          '\'SELECT ' \
          '   {pivot_field} AS vehicle_type, ' \
          '   extract(month FROM obs_date), ' \
          '   {summary_stat}({value_field}) ' \
          '  FROM (SELECT DISTINCT * FROM {table_name}) AS {table_name} ' \
          '  WHERE {pivot_field} IS NOT NULL ' \
          '  AND obs_date BETWEEN \'\'{year}-05-28\'\' AND \'\'{year}-09-15\'\' ' \
          '  {other_criteria} ' \
          '  GROUP BY {pivot_field}, extract(month FROM obs_date) ORDER BY 1\', ' \
          '\'SELECT m from generate_series(5,9) m \'' \
          ') AS ("vehicle_type" text, "May" int, "Jun" int, "Jul" int, "Aug" int, "Sep" int);' \
        .format(**{'summary_stat': summary_stat,
                   'value_field': value_field,
                   'pivot_field': pivot_field,
                   'table_name': table_name,
                   'year': str(year),
                   'other_criteria': other_criteria
                   }
                )
    # Execture query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # Combine vehicle types as necessary
    counts.set_index('vehicle_type', inplace=True)
    for out_name, in_names in dissolve_names.iteritems():
        in_names = [n for n in in_names if n in counts.index]
        counts.loc[out_name] = counts.loc[in_names].sum(axis=0)
        counts.drop(in_names, inplace=True)
    counts['total'] = counts.sum(axis=1)

    return counts


# table_name: print_name
SIMPLE_COUNT_QUERIES = {'tek_campers',
                        'photographers',
                        'accessibility',
                        'nps_vehicles',
                        'subsistence',
                        'right_of_way',
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
               'right_of_way':                  'Inholders',
               'nps_contractors':               'Contractors',
               'Denali Backcountry Lodge':      'DBL buses',
               'Denali Backcountry Lodge pax':  'DBL pax',
               'Denali Natural History Tour':   'DNHT',
               'Denali Natural History Tour pax': 'DNHT pax',
               'Kantishna Roadhouse':           'KRH buses',
               'Kantishna Roadhouse pax':       'KRH pax',
               'North Face/Camp Denali':        'CD-NF buses',
               'North Face/Camp Denali pax':    'CD-NF pax',
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


def main(out_dir, connection_txt, years=None):

    # If none given, just used the current year
    if not years:
        years = [datetime.now().year]
    # If passed from the command line, it will by in the form 'year1, year2'
    else:
        years = [int(y.strip()) for y in years.split(',')]

    connection_info = {}
    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
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

    yearly_data = []
    for year in years:

        # Query buses
        bus_names = {'VTS': ['Camper', 'Shuttle', 'Other'],#['Shuttle'],#
                          'Tour': ['Kantishna Experience', 'Eielson Excursion', 'Tundra Wilderness Tour', 'Windows Into Wilderness']#['Tundra Wilderness Tour']#
                     }
        kwargs = {'dissolve_names': bus_names,
                  'other_criteria': 'is_training = \'\'false\'\''}
        bus_vehicles = crosstab_query(engine, 'buses', 'bus_type', 'bus_type', year, **kwargs)
        bus_passengers = crosstab_query(engine, 'buses', 'bus_type', 'n_passengers', year, summary_stat='SUM', **kwargs)
        bus_passengers.index = [ind + ' pax' for ind in bus_passengers.index]

        #training_criteria = 'is_training AND bus_type IN (%s)' % ', '.join(["'%s'" % item for k, v in bus_names.iteritems() for item in v])
        training_names = {'JV training': [item for k, v in bus_names.iteritems() for item in v],
                          'Lodge bus training': ['North Face/Camp Denali', 'Kantishna Roadhouse', 'Denali Backcountry Lodge']}
        training_buses = crosstab_query(engine, 'buses', 'bus_type', 'bus_type', year, other_criteria='is_training', dissolve_names=training_names)

        # Query nps_approved
        approved_vehicles = crosstab_query(engine, 'nps_approved', 'approved_type', 'approved_type', year, other_criteria='destination <> \'\'Primrose/Mile 17\'\'')
        # Get concessionaire (i.e., JV) trips to Primrose separately because it's not included in the GMP count
        approved_vehicles_primrose = crosstab_query(engine, 'nps_approved', 'approved_type', 'approved_type', year, other_criteria='destination = \'\'Primrose/Mile 17\'\'')
        approved_vehicles_primrose = approved_vehicles_primrose.reindex(['Concessionaire'])
        approved_vehicles_primrose.index = ['Concessionaire (Primrose)']

        # Query all other vehicle types with a regular GROUP BY query
        simple_counts = []
        for table_name in SIMPLE_COUNT_QUERIES:
            simple_counts.append(simnple_query(engine, table_name, year, other_criteria='destination <> \'Primrose/Mile 17\''))
        simple_counts = pd.concat(simple_counts, sort=False)

        # Get tek and accessibility passengers and number of cyclists
        accessibility_passengers = simnple_query(engine, 'accessibility', year, summary_field='n_passengers', summary_stat='SUM', other_criteria='destination <> \'Primrose/Mile 17\'')
        accessibility_passengers.index = [PRINT_NAMES['accessibility'] + ' pax']
        tek_passengers = simnple_query(engine, 'tek_campers', year, summary_field='n_passengers', summary_stat='SUM')
        tek_passengers.index = [PRINT_NAMES['tek_campers'] + ' pax']
        cyclists = simnple_query(engine, 'cyclists', year, summary_field='n_passengers', summary_stat='SUM')
        cyclists.index = [PRINT_NAMES['cyclists']]

        all_data = pd.concat([bus_vehicles,
                             bus_passengers,
                             training_buses,
                             approved_vehicles,
                             approved_vehicles_primrose,
                             simple_counts,
                             accessibility_passengers,
                             tek_passengers,
                              cyclists],
                             sort=False)

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

    # Combine all years into one df
    all_data = pd.concat(yearly_data, axis=1)
    last_year = years[-1]
    for year in years[:-1]:
        all_data.loc[:, ('total_pct_change', 'from_%s' % year)] = \
            ((all_data.loc[:, (last_year, 'total')] - all_data.loc[:, (year, 'total')]) /
             all_data.loc[:, (year, 'total')] * 100)\
                .round(1)

    out_basename = 'ridership_%s_%s.csv' % (years[0], years[-1]) if len(years) > 1 else 'ridership_%s.csv' % years[0]
    out_csv = os.path.join(out_dir, out_basename)
    all_data.to_csv(out_csv)




