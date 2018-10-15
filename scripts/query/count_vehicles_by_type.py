'''
Query vehicle counts by day, month, or year for a specified date range

Usage:
    count_vehicles_by_type.py <connection_txt> <start_date> <end_date> (--out_dir=<str> | --out_csv=<str>) --summarize_by=<str> [--queries=<str>] [--plot_types=<str>] [--strip_data] [--plot_vehicle_limits] [--use_gmp_dates]

Examples:
    python count_vehicles_by_type.py C:\Users\shooper\proj\savagedb\connection_info.txt "5/1/1997" "9/15/2017"--out_csv="C:\Users\shooper\Desktop\delete.csv" --plot_types="grouped bar" --summarize_by="year" --queries="pov" -s -g


Required parameters:
    connection_txt      text file containing information to connect to the DB. Each line
                        in the text file must be in the form 'variable_name; variable_value.'
                        Required variables: username, password, ip_address, port, db_name
    start_date          string in the form mm/dd/yyyy indicating the first day of the date range
                        to query
    end_date            string in the form mm/dd/yyyy indicating the last day of the date range
                        to query

Options:
    -h, --help                  Show this screen.
    --out_dir=<str>             path to the directory to store the output text file. If given, output text file
                                will be saved to a file named ridership_<min_year>_<max_year>.csv will be written.
                                If out_dir is not specified, out_csv must be given
    --out_csv=<str>             path to output text file. If out_csv is not specified, out_dir must be given
    --plot_types=<str>          indicates the type of plot to use. Options: 'line', 'grouped bar', or
                                'stacked bar' (the default)
    --summarize_by=<str>        string indicating the unit of time to use for summarization. Valid options are
                                'day' or 'doy', 'month', or 'year'
    --queries=<str>             comma-separated list of data categories to query and plot. Valid options are
                                'summary', 'buses', 'nps', and 'pov'. If none specified, all queries are run.
    -s, --strip_data            indicates whether or not to remove the first and last sets of consecutive null
                                from data (similar to str.strip()) before plotting and writing CSVs to disk.
                                Default is False.
    -p, --plot_vehicle_limits   indicates whether to plot dashed lines indicating daily limits specified by the
                                VMP (91 concessionaire buses and 160 total vehicles). This option is only sensible
                                to use with the 'doy' or 'day' plot_type since these limits are by day. Default is
                                False.
    -g, --use_gmp_dates         Limit query to GMP allocation period (5/20-9/15) in addition to start_date-end_date
'''

import os, sys
import re
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
import docopt
import warnings
import subprocess

import query


POV_TABLES = ['accessibility',
              'employee_vehicles',
              'nps_approved',
              'photographers',
              'inholders',
              'subsistence',
              'tek_campers']

SORT_ORDER = {'summary':   ['Long tour',
                            'Short tour',
                            'VTS',
                            'Other JV',
                            'Lodge bus',
                            'GOV',
                            'POV'],
              'buses':     ['Shuttle',
                            'Camper',
                            'Other',
                            'Tundra Wilderness Tour',
                            'Denali Natural History Tour',
                            'Kantishna Experience',
                            'Eielson Excursion',
                            'Windows Into Wilderness',
                            'Denali Backcountry Lodge',
                            'Kantishna Roadhouse',
                            'McKinley Gold Camp',
                            'North Face/Camp Denali',
                            'Shuttle TRN',
                            'Camper TRN',
                            'Other TRN',
                            'Tundra Wilderness Tour TRN',
                            'Denali Natural History Tour TRN',
                            'Denali Backcountry Lodge TRN',
                            'Kantishna Experience TRN',
                            'Kantishna Roadhouse TRN',
                            'McKinley Gold Camp TRN',
                            'North Face/Camp Denali TRN'],
              'pov':       ['Researchers',
                            'Photographers',
                            'NPS employees',
                            'Inholders',
                            'Tek campers',
                            'Other'],
              'total':      [],
              'nps':        []
              }

HORIZONTAL_LINES = [91, 160]

COLORS = {'summary':   {'Long tour':  '#462970',
                        'Short tour': '#6255A4',
                        'VTS':        '#5C7CB0',
                        'Other JV':   '#6DB1B3',
                        'Lodge bus':  '#A88455',
                        'GOV':        '#CCB974',
                        'POV':        '#C44E52'},
          'buses':     {'Shuttle':                       '#B43234',
                        'Camper':                        '#CB7F2C',
                        'Other':                         '#E8DF60',
                        'Tundra Wilderness Tour':        '#282C69',
                        'Denali Natural History Tour':   '#2A4598',
                        'Kantishna Experience':          '#449FC0',
                        'Eielson Excursion':             '#99D1A7',
                        'Windows Into Wilderness':       '#D4E7B2',
                        'Denali Backcountry Lodge':      '#4F2369',
                        'Kantishna Roadhouse':           '#9D237E',
                        'McKinley Gold Camp':            '#E2579D',
                        'North Face/Camp Denali':        '#F4B6BB',
                        'Shuttle TRN':                   '#A85C5E',
                        'Camper TRN':                    '#AF8252',
                        'Other TRN':                     '#DBD68C',
                        'Tundra Wilderness Tour TRN':    '#5B5E88',
                        'Denali Natural History Tour TRN': '#7681A6',
                        'Kantishna Experience TRN':      '#A5CEDD',
                        'Denali Backcountry Lodge TRN':  '#624C70',
                        'Kantishna Roadhouse TRN':       '#AB5C96',
                        'McKinley Gold Camp TRN':        '#E39ABF',
                        'North Face/Camp Denali TRN':    '#F3E0E1'},
          'pov':       {'Researchers':   '#B24D4E',
                        'Photographers': '#587C97',
                        'NPS employees': '#639562',
                        'Inholders':     '#89648F',
                        'Tek campers':   '#BF7F3E',
                        'Other':         '#CDCB62'},
          'nps':        { },
          'total':      {0: '#587C97'}
          }


def get_date_range(start_date, end_date, date_format='%Y-%m-%d', summarize_by='doy'):

    FREQ_STRS = {'doy':         'D',
                 'month':       'M',
                 'year':        'Y',
                 'hour':        'H',
                 'halfhour':    '30min'
                 }


    date_range = pd.date_range(datetime.strptime(start_date, date_format),
                               datetime.strptime(end_date, date_format),
                               freq=FREQ_STRS[summarize_by]
                               )
    # For months and years, need to add 1
    if summarize_by == 'year':
        date_range = pd.to_datetime(pd.concat([pd.Series(date_range - pd.offsets.YearBegin()),
                                               pd.Series(date_range + pd.offsets.YearBegin())])
                                    .unique()
                                    )
    elif summarize_by == 'month':
        date_range = pd.to_datetime(pd.concat([pd.Series(date_range - pd.offsets.MonthBegin()),
                                               pd.Series(date_range + pd.offsets.MonthBegin())])
                                    .unique()
                                    )
    # For day, hour, halfhour, clip the last one because it rolls over in the next interval
    else:
        date_range = date_range[:-1]

    return date_range


def filter_output_fields(category_sql, engine, mapping_dict):

    with engine.connect() as conn, conn.begin():
        actual_fields = pd.read_sql(category_sql, conn)

    field_column_name = actual_fields.columns[0]
    matches = pd.merge(pd.DataFrame(pd.Series(mapping_dict), columns=['field_name']), actual_fields,
                       left_index=True, right_on=field_column_name, how='inner')

    return matches.set_index(field_column_name).sort_index()


def get_output_field_names(date_range, summarize_by, return_dict=False, filter_sql=None, engine=None):

    FORMAT_STRS = {'doy':       ('%j', '%b_%d_%y', int),
                   'month':     ('%m', '%b', int),
                   'year':      ('%Y', '_%Y', int),
                   'hour':      ('%H', '_%H', int),
                   'halfhour':  ('%Y-%m-%d %H-%M-%S', '_%H_%M',
                                 lambda x: pd.to_datetime(x, format='%Y-%m-%d %H-%M-%S')
                                 ) # just pd.to_datetime without a format doesn't keep minutes
                   }

    # in_format is sort of misnomer -- it's the format that a crosstab query would produce. The out_format
    #   is what those columns should be transformed to in the output dataframe
    in_format, out_format, in_function = FORMAT_STRS[summarize_by]

    names = date_range.strftime(out_format).str.lower()
    # For regular GROUP BY (i.e., simple) queries, return a dictionary where the keys are the columns
    #   the SQL query will produce and the values are the output column names. Also necessary for filtering
    #   the output field names if filter_sql is given
    name_mapping = dict(zip(pd.Series(date_range.strftime(in_format)).apply(in_function),
                            names)
                        )

    #keys = pd.to_datetime(names, format=out_format).strftime(in_format).to_series().apply(in_function)

    # If a filter sql query and a DB connection were given, return only names that exist for the given sql query
    if filter_sql and engine:
        '''with engine.connect() as conn, conn.begin():
            actual_columns = pd.read_sql(filter_sql, conn).values.flatten()
            actual_names = [datetime.strftime(out_format, value).lower() for value in map(in_function, actual_columns)]
            names = names[names.isin(actual_names)]'''
        name_mapping = filter_output_fields(filter_sql, engine, name_mapping)
        names = name_mapping.values.ravel()
        if return_dict:
            name_mapping = name_mapping.squeeze().to_dict()

    return names if not return_dict else name_mapping


def get_x_labels(date_range, summarize_by):

    FORMAT_STRS = {'doy':       '%m/%d/%y',
                   'month':     '%b',
                   'year':      '%Y',
                   'hour':      '%H:%M',
                   'halfhour':  '%H:%M'
                   }
    names = date_range.strftime(FORMAT_STRS[summarize_by]).unique().to_series()
    names.index = np.arange(len(names))

    return names


def get_hourly_sql(table_name, start_str, end_str, value_field, other_criteria='', query_type='crosstab', field_names='*', summary_stat='COUNT', summarize_by='halfhour'):

    date_clause = "AND datetime BETWEEN ''{start_str}'' AND ''{end_str}'' " \
        .format(start_str=start_str, end_str=end_str)

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    #   First check whether it's necessary to modify the statement
    modify_criteria = other_criteria.strip() and \
                      not (other_criteria.lower().strip().startswith('and ') or
                           other_criteria.lower().strip().startswith('or '))
    if modify_criteria:
        other_criteria = 'AND ' + other_criteria

    where_clause = ('WHERE %s IS NOT NULL ' % value_field) + date_clause + other_criteria

    # Specifies number of seconds per interval defined by the query
    interval_seconds = '1800' if summarize_by == 'halfhour' else '3600'

    if query_type == 'crosstab':
        date_range = get_date_range(start_str, end_str, summarize_by=summarize_by)
        output_fields = get_output_field_names(date_range, summarize_by)
        output_fields_str = 'vehicle_type text, ' + (' int, '.join(output_fields)) + ' int'
        sql = "SELECT * FROM crosstab( \n" \
              "'SELECT \n" \
              "     {value_field}, \n" \
              "     to_timestamp(FLOOR(EXTRACT(epoch FROM datetime::TIMESTAMPTZ)/{seconds}) * {seconds}) AS {summarize_by}, \n" \
              "     count(datetime) \n" \
              "FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n" \
              "{where_clause} \n" \
              "GROUP BY {summarize_by}, {value_field}  ORDER BY 1', \n" \
              "'SELECT generate_series( ''{start_str} 00:00''::TIMESTAMPTZ, \n" \
              "                          ''{start_str} 23:59:59''::TIMESTAMPTZ, \n" \
              "                          ''{interval}''::INTERVAL)'\n" \
              ") AS ({output_fields_str});" \
            .format(value_field=value_field,
                    seconds=interval_seconds,
                    summarize_by=summarize_by,
                    table_name=table_name,
                    field_names=field_names,
                    where_clause=where_clause,
                    start_str=start_str,
                    interval='30 minute' if summarize_by == 'halfhour' else '1 hour',
                    output_fields_str=output_fields_str
                    )
    else:

        sql = 'SELECT \n' \
              '   to_timestamp(FLOOR(EXTRACT(epoch FROM datetime::TIMESTAMPTZ)/{seconds}) * {seconds})::TIMESTAMP AS {summarize_by}, \n' \
              '   {summary_stat}({value_field}) AS {table_name} \n' \
              'FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n' \
              '{where_clause} \n' \
              'GROUP BY {summarize_by} ' \
              'ORDER BY {summarize_by};' \
            .format(seconds=interval_seconds,
                    summarize_by=summarize_by,
                    summary_stat=summary_stat,
                    value_field=value_field,
                    table_name=table_name,
                    where_clause=where_clause.replace("''", "'"),
                    field_names=field_names
                    )

    return sql


def query_all_vehicles(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria=''):

    ########## Query non-training buses
    buses, training_buses = query_buses(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, is_subquery=True, other_criteria=other_criteria)
    buses.add(training_buses, fill_value=0)


    # Query GOVs
    simple_output_fields = get_output_field_names(date_range, summarize_by, return_dict=True)
    where_clause = 'datetime BETWEEN \'{start_date}\' AND \'{end_date}\' ' \
                   'AND destination NOT LIKE \'Primrose%%\' '\
        .format(start_date=start_date, end_date=end_date) \
        + other_criteria
    if 'hour' in summarize_by:
        sql = get_hourly_sql('nps_vehicles', start_date, end_date, 'datetime', other_criteria=where_clause, query_type='simple', field_names=field_names['nps_vehicles'])
    else:
        sql = None
    govs = query.simple_query(engine, 'nps_vehicles', field_names=field_names['nps_vehicles'], other_criteria=where_clause, date_part=summarize_by, output_fields=simple_output_fields, sql=sql)
    govs.index = ['GOV']


    # POVs
    povs = pd.DataFrame(np.zeros((1, buses.shape[1] - 1), dtype=int),
                        columns=output_fields,
                        index=['POV'])
    for table_name in POV_TABLES:
        if 'hour' in summarize_by:
            sql = get_hourly_sql(table_name, start_date, end_date, 'datetime',
                                   other_criteria=where_clause, query_type='simple',
                                   field_names=field_names[table_name])
        else:
            sql = None
        df = query.simple_query(engine, table_name, field_names=field_names[table_name],
                                other_criteria=where_clause, date_part=summarize_by,
                                output_fields=simple_output_fields, sql=sql)
        df.index = ['POV']
        povs = povs.add(df, fill_value=0)

    data = pd.concat([buses, govs, povs], sort=False)
    if sort_order:
        data = data.reindex(sort_order)

    return data


def query_buses(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, is_subquery=False, sort_order=None, other_criteria=''):

    ########## Query non-training buses
    bus_other_criteria = "is_training = ''false'' " \
                         "AND datetime BETWEEN ''{start_date}'' AND ''{end_date}'' "\
                        .format(start_date=start_date, end_date=end_date) \
                        + other_criteria.replace("'", "''")


    kwargs = {'other_criteria': bus_other_criteria,
              'field_names': field_names['buses'],
              'date_part': summarize_by}

    # If this function is being called within query_all_vehicles(), set the names to aggregate. If this function
    #   is being called as just a query of buses, don't aggregate at all so no need to set dissolve_names
    if is_subquery:
        bus_names = {'VTS': ['Shuttle', 'Camper'],
                     'Other JV': ['Other'],
                     'Long tour': ['Kantishna Experience', 'Eielson Excursion',
                                   'Tundra Wilderness Tour', 'Windows Into Wilderness'],
                     'Short tour': ['Denali Natural History Tour'],
                     'Lodge bus': ['Kantishna Roadhouse', 'Denali Backcountry Lodge',
                                   'North Face/Camp Denali']
                     }
        kwargs['dissolve_names'] = bus_names

    # Make sure the field names match what the crosstab query will produce. If any fields are missing,
    #   crosstab() will throw an error. Only necessary for summarize_by == doy, month, or year because hour
    #   and halfhour produce their own relevant columns in get_hourly_sql()
    if 'hour' not in summarize_by:
        filter_sql = 'SELECT DISTINCT extract({date_part} FROM datetime) FROM {table_name} {where_clause} '\
            .format(date_part=summarize_by, table_name='buses',
                    where_clause='WHERE bus_type IS NOT NULL AND ' + bus_other_criteria
                    )\
            .replace("''", "'")
        bus_output_fields = get_output_field_names(date_range, summarize_by, filter_sql=filter_sql, engine=engine)
        kwargs['output_fields'] = 'vehicle_type text, ' + (' int, '.join(bus_output_fields)) + ' int'
    else:
        kwargs['sql'] = get_hourly_sql('buses', start_date, end_date, 'bus_type',
                                         other_criteria=bus_other_criteria,
                                         query_type='crosstab', field_names=field_names['buses'],
                                       summarize_by=summarize_by)

    buses = query.crosstab_query(engine, 'buses', 'bus_type', 'bus_type', **kwargs)

    ######### Query training buses
    trn_other_criteria = "is_training " \
                         "AND datetime BETWEEN ''{start_date}'' AND ''{end_date}'' " \
                        .format(start_date=start_date, end_date=end_date) \
                        + other_criteria.replace("'", "''")

    kwargs['other_criteria'] = trn_other_criteria

    if is_subquery:
        kwargs['dissolve_names'] = {'Other JV': ['Shuttle', 'Camper', 'Kantishna Experience',
                                                 'Eielson Excursion', 'Tundra Wilderness Tour',
                                                 'Windows Into Wilderness', 'Denali Natural History Tour'],
                                    'Lodge bus': ['Kantishna Roadhouse', 'Denali Backcountry Lodge',
                                                  'North Face/Camp Denali']
                                    }

    # Get appropriate field names as with non-training buses
    if 'hour' not in summarize_by:
        filter_sql = 'SELECT DISTINCT extract({date_part} FROM datetime) FROM {table_name} {where_clause} '\
            .format(date_part=summarize_by, table_name='buses',
                    where_clause='WHERE bus_type IS NOT NULL AND ' + trn_other_criteria
                    )\
            .replace("''", "'")
        trn_output_fields = get_output_field_names(date_range, summarize_by, filter_sql=filter_sql, engine=engine)
        trn_fields_str = 'vehicle_type text, ' + (' int, '.join(trn_output_fields)) + ' int'
        kwargs['output_fields'] = trn_fields_str

    else:
        kwargs['sql'] = get_hourly_sql('buses', start_date, end_date, 'bus_type',
                                         other_criteria=kwargs['other_criteria'],
                                         query_type='crosstab', field_names=field_names['buses'],
                                       summarize_by=summarize_by)
    training_buses = query.crosstab_query(engine, 'buses', 'bus_type', 'bus_type', **kwargs)

    if is_subquery:
        return buses, training_buses

    training_buses.index = training_buses.index + ' TRN'

    data = pd.concat([buses, training_buses], sort=False)
    if sort_order:
        data = data.reindex(sort_order)

    return data


def query_total(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria=''):

    data = query_all_vehicles(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, other_criteria=other_criteria)
    totals = pd.DataFrame(data.sum(axis=0)).T

    return totals


def query_nps(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria=''):

    other_criteria = "datetime BETWEEN ''{start_date}'' AND ''{end_date}'' "\
                        .format(start_date=start_date, end_date=end_date) \
                        + other_criteria.replace("'", "''")

    if 'hour' in summarize_by:
        sql = get_hourly_sql('nps_vehicles', start_date, end_date, 'datetime', query_type='crosstab',
                             field_names=field_names['nps_vehicles'], summarize_by=summarize_by)
    else:
        sql = None

    filter_sql = 'SELECT DISTINCT extract({date_part} FROM datetime) FROM nps_vehicles {where_clause} '\
        .format(date_part=summarize_by, where_clause='WHERE work_group IS NOT NULL AND ' + other_criteria
                )\
        .replace("''", "'")
    output_fields = get_output_field_names(date_range, summarize_by, filter_sql=filter_sql, engine=engine)
    output_field_str = 'vehicle_type text, ' + (' int, '.join(output_fields)) + ' int'
    data = query.crosstab_query(engine, 'nps_vehicles', 'work_group', 'datetime', other_criteria=other_criteria, date_part=summarize_by, output_fields=output_field_str, sql=sql)

    if sort_order:
        data = data.reindex(sort_order)

    return data


def query_pov(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria=''):

    OTHER_CRITERIA = {'nps_employee':   "AND destination IN ('Toklat', \'Wonder Lake\') ",
                      'other_employee': "AND destination NOT IN ('Toklat', 'Wonder Lake') ",
                      'researcher':     "AND destination NOT LIKE 'Primrose%%' AND "
                                        "approved_type = 'Researcher' ",
                      'other_approved': "AND destination NOT LIKE 'Primrose%%' AND "
                                        "approved_type <> 'Researcher' "
                      }

    if 'hour' in summarize_by:
        inholder_sql = get_hourly_sql('inholders', start_date, end_date, 'datetime', query_type='simple',
                                      field_names=field_names['inholders'], summarize_by=summarize_by)

        nps_employee_sql = get_hourly_sql('employee_vehicles', start_date, end_date, 'datetime',
                                        query_type='simple', field_names=field_names['employee_vehicles'],
                                        other_criteria=OTHER_CRITERIA['nps_employee'], summarize_by=summarize_by)

        other_employee_sql = get_hourly_sql('employee_vehicles', start_date, end_date, 'datetime',
                                        query_type='simple', field_names=field_names['employee_vehicles'],
                                        other_criteria=OTHER_CRITERIA['other_employee'], summarize_by=summarize_by)

        propho_sql = get_hourly_sql('photographers', start_date, end_date, 'datetime',
                                      query_type='simple', field_names=field_names['photographers'], summarize_by=summarize_by)

        researcher_sql = get_hourly_sql('nps_approved', start_date, end_date, 'datetime',
                                          query_type='simple', field_names=field_names['nps_approved'],
                                        other_criteria=OTHER_CRITERIA['researcher'], summarize_by=summarize_by)

        other_approved_sql = get_hourly_sql('nps_approved', start_date, end_date, 'datetime',
                                     query_type='simple', field_names=field_names['nps_approved'],
                                     other_criteria=OTHER_CRITERIA['other_approved'], summarize_by=summarize_by)

        accessibility_sql = get_hourly_sql('accessibility', start_date, end_date, 'datetime',
                                     query_type='simple', field_names=field_names['accessibility'],summarize_by=summarize_by)

        subsistence_sql = get_hourly_sql('subsistence', start_date, end_date, 'datetime',
                                     query_type='simple', field_names=field_names['subsistence'], summarize_by=summarize_by)

        tek_sql = get_hourly_sql('tek_campers', start_date, end_date, 'datetime',
                                     query_type='simple', field_names=field_names['tek_campers'],summarize_by=summarize_by)


    else:
        inholder_sql, nps_employee_sql, other_employee_sql, propho_sql, researcher_sql,\
            other_approved_sql, accessibility_sql, subsistence_sql, tek_sql =\
            None, None, None, None, None, None, None, None, None

    sql_statements = [
        (inholder_sql,        'inholders',      'Inholders',    ''),
        (nps_employee_sql,    'employee_vehicles', 'NPS employees',OTHER_CRITERIA['nps_employee']),
        (other_employee_sql,  'employee_vehicles', 'Other',        OTHER_CRITERIA['other_employee']),
        (propho_sql,          'photographers',     'Photographers', ''),
        (researcher_sql,      'nps_approved',      'Researchers',  OTHER_CRITERIA['researcher']),
        (other_approved_sql,  'nps_approved',      'Other',        OTHER_CRITERIA['other_approved']),
        (accessibility_sql,   'accessibility',     'Other',        ''),
        (subsistence_sql,     'subsistence',       'Other',        ''),
        (tek_sql,             'tek_campers',       'Tek campers',  '')
    ]

    date_range = get_date_range(start_date, end_date, summarize_by=summarize_by)
    output_fields = get_output_field_names(date_range, summarize_by, return_dict=True)
    all_data = []
    for sql, table_name, print_name, criteria in sql_statements:
        data = query.simple_query(engine, table_name, field_names=field_names[table_name],
                                  date_part=summarize_by, output_fields=output_fields, sql=sql,
                                  other_criteria="datetime BETWEEN '%s' AND '%s' " % (start_date, end_date) + criteria + other_criteria)
        data.index = [print_name]
        all_data.append(data)

    data = pd.concat(all_data, sort=False)
    data = data.groupby(data.index).sum(axis=0)

    if sort_order:
        data = data.reindex(sort_order)

    return data


def strip_dataframe(data):
    '''Remove null "edges" of a dataframe'''

    nans = data.isnull()
    data = data.fillna(0)
    cols = data.columns.to_series()
    cols.index = range(data.shape[1])
    isnull_index = cols.index[(data == 0).all(axis=0)].to_series()
    nonconsecutive_null_cols = isnull_index[1:][~(isnull_index.diff() == 1)[1:]]  # drop first because diff() produces NaN
    first_nonconsecutive = nonconsecutive_null_cols.min()
    last_nonconsecutive = nonconsecutive_null_cols.max()
    drop_inds = pd.concat([isnull_index.loc[:first_nonconsecutive].iloc[:-1],
                           isnull_index.loc[last_nonconsecutive:]])
    data = data.drop(cols[drop_inds], axis=1)

    # fill NaNs back in
    nans.drop(cols[drop_inds], axis=1, inplace=True)
    data[nans] = np.NaN

    return data, drop_inds


def plot_bar(all_data, x_labels, out_png, bar_type='stacked', vehicle_limits=None, title=None, legend_title='', max_xticks=20, colors={}):


    n_vehicles, n_dates = all_data.shape
    spacing_factor = 3 if bar_type == 'stacked' else int(n_vehicles * 1.3)
    bar_width = 1

    ax = plt.gca()
    grouped_index = np.arange(0, n_dates * spacing_factor, spacing_factor)
    stacked_index = np.arange(n_dates) * spacing_factor
    bar_index = np.arange(n_vehicles) - n_vehicles / 2  # /2 centers bar for grouped bar chart

    # PLot horizontal lines showing max concessionaire buses and total vehicles per day
    if vehicle_limits:
        for y_value in vehicle_limits:
            ax.plot([-stacked_index.max() * 2, stacked_index.max() * 2],
                    [y_value, y_value], '--', alpha=0.3, color='0.3',
                    zorder=0)

    last_top = np.zeros(n_dates)
    for i, (vehicle_type, data) in enumerate(all_data.iterrows()):
        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        # If the bars are stacked, just pass x indices that are evenly spaced
        #   If they're grouped, make sure they're offset
        x_inds = stacked_index if bar_type == 'stacked' else grouped_index - bar_width * bar_index[i]

        ax.bar(x_inds, data, bar_width, bottom=last_top, label=vehicle_type, zorder=i + 1, color=color)
        last_top += data if bar_type == 'stacked' else 0

    x_tick_inds = stacked_index if bar_type == 'stacked' else grouped_index
    x_tick_interval = max(1, int(round(n_dates/float(max_xticks))))
    plt.xticks(x_tick_inds[::x_tick_interval], x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')

    # If adding horizonal lines, make sure their values are noted on the y axis. Otherwise, just
    #   use the default ticks
    if vehicle_limits:
        plt.yticks(np.unique((list(ax.get_yticks()) + vehicle_limits)))

    # Set enough space on either end of the plot
    if bar_type == 'stacked':
        plt.xlim([-1, x_tick_inds.max() + 1])
    else:
        plt.xlim([-n_vehicles/2, x_tick_inds.max() + n_vehicles/2 + 1])

    if not title:
        title = 'Vehicles past Savage River, %s - %s' % (x_labels.iloc[0], x_labels.iloc[-1])
    plt.title(title)

    sns.despine()

    # Grouped bar charts are too small to read at the default width so widen if bars are grouped
    figure = plt.gcf()
    width = figure.get_figwidth()
    # Make sure the width scale is between 1 and 3
    width_scale = max(1, min(n_dates/float(max_xticks), 3))
    figure.set_figwidth(width * width_scale)

    if n_vehicles > 1:
        handles, labels = ax.get_legend_handles_labels()
        legend = plt.legend(handles[::-1], labels[::-1], bbox_to_anchor=(1.04, 0),
                   loc='lower left', title=legend_title, frameon=False)
        legend._legend_box.align = 'left'
        max_label_length = max(map(len, labels))
        proportional_adjustment = (0.12 * max_label_length/30.0)  # type: float
        right_adjustment = 0.75 - proportional_adjustment
        print right_adjustment
        plt.subplots_adjust(right=right_adjustment, bottom=.15) # make room for legend and x labels

    plt.savefig(out_png.replace('.png', '_%s.png' % bar_type), dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop


def plot_line(all_data, x_labels, out_png, vehicle_limits=None, title=None, legend_title=None, max_xticks=20, colors={}):

    n_vehicles, n_dates = all_data.shape
    for vehicle_type, counts in all_data.iterrows():
        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        plt.plot(xrange(n_dates), counts, '-', color=color, label=vehicle_type)

    x_tick_interval = max(1, int(round(n_dates / float(max_xticks))))
    plt.xticks(xrange(0, n_dates, x_tick_interval), x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')


    if not title:
        title = 'Vehicles past Savage River, %s - %s' % (x_labels.iloc[0], x_labels.iloc[-1])
    plt.title(title)

    if n_vehicles > 1:
        legend = plt.legend(bbox_to_anchor=(1.04, 0), loc='lower left', title=legend_title, frameon=False)
        legend._legend_box.align = 'left'
        plt.subplots_adjust(right=0.73, bottom=.15) # make room for legend and x labels

    max_vehicle_limit = max(vehicle_limits) if vehicle_limits else 0
    #plt.ylim([0, max(max_vehicle_limit, all_data.values.max())])
    sns.despine()

    # Grouped bar charts are too small to read at the default width so widen if bars are grouped
    figure = plt.gcf()
    width = figure.get_figwidth()
    # Make sure the width scale is between 1 and 3
    width_scale = max(1, min(n_dates/float(max_xticks), 3))
    figure.set_figwidth(width * width_scale)

    plt.savefig(out_png.replace('.png', '_line.png'), dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop


def plot_best_fit(all_data, x_labels, out_png, vehicle_limits=None, title=None, legend_title=None, max_xticks=20, colors={}):

    n_vehicles, n_dates = all_data.shape
    for vehicle_type, counts in all_data.iterrows():
        x = np.arange(n_dates)
        slope, intercept = np.polyfit(x, counts, 1)

        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        x_inds = np.array([0, n_dates])
        y_vals = x_inds * slope + intercept

        plt.plot(x_inds, y_vals, '-', color=color, label=vehicle_type)
        plt.scatter(x, counts, color=color, alpha=0.5, label='')

    x_tick_interval = max(1, int(round(n_dates / float(max_xticks))))
    plt.xticks(xrange(0, n_dates, x_tick_interval), x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')


    if not title:
        title = 'Vehicles past Savage River, %s - %s' % (x_labels.iloc[0], x_labels.iloc[-1])
    plt.title(title)

    if n_vehicles > 1:
        legend = plt.legend(bbox_to_anchor=(1.04, 0), loc='lower left', title=legend_title, frameon=False)
        legend._legend_box.align = 'left'
        plt.subplots_adjust(right=0.73, bottom=.15) # make room for legend and x labels

    max_vehicle_limit = max(vehicle_limits) if vehicle_limits else 0
    plt.ylim([0, max(max_vehicle_limit, all_data.values.max())])
    sns.despine()

    # Grouped bar charts are too small to read at the default width so widen if bars are grouped
    figure = plt.gcf()
    width = figure.get_figwidth()
    # Make sure the width scale is between 1 and 3
    width_scale = max(1, min(n_dates/float(max_xticks), 3))
    figure.set_figwidth(width * width_scale)

    plt.savefig(out_png.replace('.png', '_best_fit.png'), dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop


def write_metadata(out_dir, queries, summarize_by, start_date, end_date, plot_vehicle_limits):

    QUERY_DESCRIPTIONS = {'summary':    'all vehicles aggregated in broad categories',
                          'buses':      'buses by each type found in the "bus_type" column of the "buses" table',
                          'nps':        'NPS vehicles by work group',
                          'pov':        'all private vehicles by type',
                          'total':      'total of all vehicles'}

    command = subprocess.list2cmdline(sys.argv)

    descr = "This folder contains queried data and derived plots from the Savage Box database. Data were summarize by {summarize_by} for dates between {start} and {end}. "\
        .format(summarize_by=summarize_by, start=start_date, end=end_date)
    query_descr = "Queries run include:\n%s" + "\n\t\t-".join([QUERY_DESCRIPTIONS[q] for q in queries])

    if plot_vehicle_limits:
        "\nAdditionally, queries were limited to only observations that occurred between May 20 and Sep 15"

    msg = "For questions, please contact Sam Hooper, samuel_hooper@nps.gov\n" \
          "File descriptions:\n" \
          "\tall_usage.csv - raw bc user data per day per unit\n" \
          "\t\tPertinent field descriptions:\n" \
          "\t\t\t-n_people: number of individual people permitted for a BC unit\n" \
          "\t\t\t-n_parties: number of parties permitted for a BC unit\n" \
          "\t\t\t-quota: max number of individuals allowed to stay in a BC unit according the the BCMP\n" \
          "\t\t\t-pct_occupied: n_people / quota\n" \
          "\t\t\t-is_full: boolean value indicating if n_people is equal to quota\n" \
          "\t\t\t-is_full_by_single_party: boolean indicating if the unit is full and there was only one party in the unit\n" \
          "\n\tavg_use_per_day_2013_2017.csv - bc user data per unit per day averaged across all years for each day\n" \
          "\t\tPertinent field descriptions:\n" \
          "\t\t\t-avg_pct_occupied: pct_occupied averaged across all years for each day of the year\n" \
          "\t\t\t-pct_time_full: percent of the time a BC unit is full on a given day of the year\n" \
          "\t\t\t-pct_time_full_by_single_party: percent of the time a BC unit is full from only 1 party on a given day of the year\n" \
          "\n\tuse_per_year_2013_2017.csv - same as above but all days are summarized per year. Additional fields showing sums are self explanatory.\n" \
          "\n\tavg_use_per_day_2013_2017_unit15_<month_number>_<month_name>.png - plot of the three fields in avg_user_per_day_2013_2017.csv for BC unit 15 (plots separated by month for legibility)\n" \
          "\n\tuse_per_year_2013_2017_unit<unit_number>.png - same as above but plotting data from user_per_year_2013_2017.csv per unit\n" \
          "\n\nSCRIPT: %(script)s\n" \
          "\nDATE PROCESSED: %(datestamp)s"

    return


def main(connection_txt, start_date, end_date, out_dir=None, out_csv=None, plot_types='stacked bar', summarize_by='day', queries=None, strip_data=False, plot_vehicle_limits=False, use_gmp_dates=False):

    QUERY_FUNCTIONS = {'summary':   query_all_vehicles,
                       'buses':     query_buses,
                       'pov':       query_pov,
                       'nps':       query_nps,
                       'total':     query_total}

    TITLE_PREFIXES = {'summary':    'Vehicles',
                      'buses':      'Buses',
                      'nps':        'NPS vehicles',
                      'pov':        'Private vehicles',
                      'total':      'Total vehicles'}

    sns.set_context('paper')
    sns.set_style('darkgrid')

    # If nothing is passed, assume that all queries should be run
    if not queries:
        queries = ['summary']#'nps', 'buses', 'other']
    # Otherwise it should be a comma-separated list
    else:
        queries = [q.strip().lower() for q in queries.split(',')]
    valid_query_strings = [q in QUERY_FUNCTIONS.keys() for q in queries]
    if not any(valid_query_strings):
        warnings.warn('No valid query type string found in queries: %s. All queries '
                             'will be run.' % ', '.join(queries))

    # Split plot types (passed as comma-separated string) into a list
    if plot_types:
        plot_types = [t.strip().lower().replace('_', ' ') for t in plot_types.split(',')]
        # Check if any recognizable strings are in plot_types
        valid_strings = [s in ['stacked bar', 'grouped bar', 'line', 'best fit', ''] for s in plot_types]
        if not any(valid_strings):
            warnings.warn('No valid plot type string found in plot_types: %s. No plots will be made.'
                          % ', '.join(plot_types))

    if not ('day' in plot_types or 'doy' in plot_types) and plot_vehicle_limits:
        warnings.warn("The '--plot_vehicle_limits' flag was passed but 'day'/'doy' was not given in plot_types, so the"
                      " vehicle limits won't make any sense. Try the command 'python count_vehicles_by_type --help'"
                      " information on valid parameters")

    # reformat dates for postgres (yyyy-mm-dd), assuming format mm/dd/yyyy
    try:
        start_datetime = datetime.strptime(start_date, '%m/%d/%Y')
        end_datetime = datetime.strptime(end_date, '%m/%d/%Y') +\
                       timedelta(days=1) # add 1 day because BETWEEN looks for dates before end date
    except:
        raise ValueError('start and end dates must be in format mm/dd/YYYY')

    # If the --use_gmp_dates flag was passed, add additional criteria to makes sure dates are at least constrained to 5/20-9/15. Also make sure the date range is appropriately clipped.
    gmp_date_criteria = ''
    if use_gmp_dates:
        gmp_date_criteria = " AND extract(doy FROM datetime) BETWEEN extract(doy FROM date (extract(year FROM datetime) || '-05-20')) AND extract(doy FROM date (extract(year FROM datetime) || '-09-16'))"
        gmp_start_datetime = datetime.strptime('5/20/%s' % start_datetime.year, '%m/%d/%Y')
        gmp_end_datetime = datetime.strptime('9/15/%s' % end_datetime.year, '%m/%d/%Y')
        start_delta = start_datetime - gmp_start_datetime
        end_delta = end_datetime - gmp_end_datetime

        if start_delta < timedelta(0):
            start_datetime += timedelta(abs(start_delta.days))
        if end_delta > timedelta(0):
            end_datetime -= timedelta(abs(end_delta.days))

    start_date = start_datetime.strftime('%Y-%m-%d')
    end_date = end_datetime.strftime('%Y-%m-%d')

    # Make a generic csv path if necessary
    if out_dir:
        # if both out_csv and out_dir are given, still just use out_csv. If just out_dir, use an informative basename
        if not out_csv:
            basename = 'vehicle_counts.csv'
            if not os.path.isdir(out_dir):
                os.mkdir(out_dir)
            out_csv = os.path.join(out_dir, basename)
    elif not out_csv:
        # If we got here, neither out_dir nor out_csv were given so raise an error
        raise ValueError('Either out_csv or out_dir must be given')

    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
    engine = query.connect_db(connection_txt)

    # Get field names that don't contain unique IDs
    field_names = query.query_field_names(engine)

    # If summarizing by day, use day of year instead
    if summarize_by == 'day':
        summarize_by = 'doy'

    # Create output field names as a string
    date_range = get_date_range(start_date, end_date, summarize_by=summarize_by)
    output_fields = get_output_field_names(date_range, summarize_by)

    x_labels = get_x_labels(date_range, summarize_by)
    # Store all dfs in a dictionary by type so we can then make plots by looping through the dict
    dfs = {}
    for query_name in queries:

        if query_name not in QUERY_FUNCTIONS:
            warnings.warn('Invalid query name found: "%s". Query names must be separated'
                                 ' by a comma and be one of the following: %s' %
                                 (query_name, ', '.join(QUERY_FUNCTIONS.keys()))
                                 )
            continue

        query_function = QUERY_FUNCTIONS[query_name]
        data = query_function(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine,
                              sort_order=SORT_ORDER[query_name], other_criteria=gmp_date_criteria)
        data.fillna(0, inplace=True)
        data = data.loc[data.total > 0]
        data.drop('total', axis=1, inplace=True)

        # Remove empty columns from edges of the data
        these_labels = x_labels.copy()
        if strip_data:
            data, drop_inds = strip_dataframe(data)
            these_labels = these_labels.drop(drop_inds) #drop the same labels

        # Write csv to disk
        this_csv_path = out_csv.replace(os.path.splitext(out_csv)[-1],
                                        '_{query_name}_by_{summarize_by}_{start_date}_{end_date}.csv'
                                            .format(query_name=query_name,
                                                    summarize_by=summarize_by,
                                                    start_date=start_datetime.strftime('%Y%m%d'),
                                                    end_date=end_datetime.strftime('%Y%m%d')
                                                    )
                                        )
        data.to_csv(this_csv_path)

        vehicle_limits = []
        if plot_vehicle_limits:
            if query_name == 'summary': vehicle_limits = [91, 160]
            elif query_name == 'buses': vehicle_limits = [91]
            elif query_name == 'total': vehicle_limits = [160]
            else: vehicle_limits = [] # doesn't make sense for other plots

        out_png = this_csv_path.replace('.csv', '.png')
        colors = COLORS[query_name]
        title = '{prefix} past Savage by {interval}, {start}-{end}'\
            .format(prefix=TITLE_PREFIXES[query_name], interval='day' if summarize_by == 'doy' else summarize_by,
                    start=these_labels.iloc[0], end=these_labels.iloc[-1])
        if 'stacked bar' in plot_types:
            plot_bar(data, these_labels, out_png, bar_type='stacked', vehicle_limits=vehicle_limits, title=title, colors=colors)
        if 'grouped bar' in plot_types:
            plot_bar(data, these_labels, out_png, bar_type='grouped', vehicle_limits=vehicle_limits, title=title, colors=colors)
        if 'line' in plot_types:
            plot_line(data, these_labels, out_png, vehicle_limits=vehicle_limits, title=title, colors=colors)
        if 'best fit' in plot_types:
            plot_best_fit(data, these_labels, out_png, vehicle_limits=vehicle_limits, title=title, colors=colors)
        '''else:
            raise ValueError('plot_type "%s" not understood. Must be either "stacked bar", "grouped bar", or "line"')'''

    # Write metadata


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    #args['strip_data'] = True if args['strip_data'] else False
    #args['plot_vehicle_limits'] = True if args['plot_vehicle_limits'] else False

    sys.exit(main(**args))
