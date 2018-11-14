'''
Query vehicle counts by day, month, or year for a specified date range

Usage:
    count_vehicles_by_type.py <connection_txt> <start_date> <end_date> (--out_dir=<str> | --out_csv=<str>) --summarize_by=<str> [--queries=<str>] [--plot_types=<str>] [--sql_values_filter=<str>] [--category_filter=<str>] [--summary_stat=<>] [--summary_field=<str>] [--aggregate_by=<str>] [--time_range=<str>] [--plot_extension=<str>] [--strip_data] [--plot_vehicle_limits] [--use_gmp_dates] [--show_stats] [--plot_totals] [--show_percents] [--remove_gaps] [--drop_null] [--write_sql] [--white_background]

Examples:
    python count_vehicles_by_type.py C:\Users\shooper\proj\savagedb\connection_info.txt 5/20/1997 9/15/2017 --out_dir=C:\Users\shooper\Desktop\plot_test --summarize_by=year --queries=summary --plot_types="best fit" -s -g


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
    --out_dir=<str>             Path to the directory to store the output text file. If given, output text file
                                will be saved to a file named ridership_<min_year>_<max_year>.csv will be written.
                                If out_dir is not specified, out_csv must be given
    --out_csv=<str>             Path to output text file. If out_csv is not specified, out_dir must be given
    --plot_types=<str>          Indicates the type of plot(s) to use. Valid options: 'line', 'bar', 'grouped bar',
                                'stacked bar', 'best fit' (for line of best fit), and 'stacked area'
    --summarize_by=<str>        String indicating the unit of time to use for summarization. Valid options are
                                'year', 'month', 'day', 'hour', and 'halfhour'
    --queries=<str>             Comma-separated list of data categories to query and plot. Valid options are
                                'summary', 'buses', 'nps', 'pov', 'bike', and 'total'. If none specified, all queries
                                are run.
    --sql_values_filter=<str>   Comma-separated list of values to return from the SQL query (if they exist)
    --category_filter=<str>     Comma-separated list of either regular expressions or strings found in SORT_ORDER of
                                this script to filter the categories of values per query type. See SORT_ORDER values
                                for a list of values per query.
    --summary_stat=<str>        Summary statistic to aggregate values in SQL query. Default is 'COUNT'
    --summary_field=<str>       Field name in the tables to calculate values from in SQL queries. Default is 'datetime'
    --aggregate_by=<str>        Secondary time step to aggregate initially counted values by. For example, if
                                summarize_by = 'day' and start_date-end_date spans multiple years, aggregate_by = 'year'
                                would calculate the summary_stat for each year by day (e.g., mean count of vehicles per
                                day for each year). Valid options are the same as the options for summarize_by plus
                                'doy' (to calculate summary_stat for anniversary dates).
    --time_range=<str>          Times of day to query between specifed as hh:mm-hh:mm. Only records where the datetime
                                field is between these two times will be summarised
    --plot_extension=<str>      File extension dictating which image format to save plots to. Options are ".png",
                                ".jpg", ".pdf", and any acceptable matplotlib image format. [default: .png]
    -s, --strip_data            Remove the first and last sets of consecutive null
                                from data (similar to str.strip()) before plotting and writing CSVs to disk.
                                Default is False.
    -p, --plot_vehicle_limits   Plot dashed lines indicating daily limits specified by the VMP (91 concessionaire buses
                                and 160 total vehicles) or yearly limits from the GMP (10,512 total vehicles per year).
                                Limits will be plotted according to the specifc query and plot types. Default is False.
    -g, --use_gmp_dates         Limit query to GMP allocation period (5/20-9/15) in addition to start_date-end_date
    -x, --show_stats            Add relevant stats to labels in the legend. Only valid for 'best fit' plot type.
    -t, --plot_totals           Additionally show totals of all vehicle types. Not valid for 'total' plot type.
    -c, --show_percents         Draw percent of totals per interval on bars (only relevant for bar chart plot_types)
    -r, --remove_gaps           Plot bars without gaps between them
    -d, --drop_null             Remove any column (date/time) without any data for the given query
    -w, --write_sql             Write a text file per query with the exact SQL statements passed to the
                                querying function
    -b, --white_background      Use the default Seaborn style (white background). If not specified, the 'dark grid'
                                style will be used
'''

import os, sys
import re
from datetime import datetime, timedelta
from dateutil import relativedelta as rd
import matplotlib.pyplot as plt
from scipy import stats
import seaborn as sns
import pandas as pd
from pandas.tseries import holiday
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
                            'Other JV bus',
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
                            'Camp Denali/North Face Lodge',
                            'Shuttle TRN',
                            'Camper TRN',
                            'Other TRN',
                            'Tundra Wilderness Tour TRN',
                            'Denali Natural History Tour TRN',
                            'Denali Backcountry Lodge TRN',
                            'Kantishna Experience TRN',
                            'Kantishna Roadhouse TRN',
                            'McKinley Gold Camp TRN',
                            'Camp Denali/North Face Lodge TRN'],
              'pov':       ['Researchers',
                            'Photographers',
                            'NPS employees',
                            'Inholders',
                            'Tek campers',
                            'Other'],
              'total':      [],
              'nps':        [],
              'bikes':      []
              }

COLORS = {'summary':   {'Long tour':  '#462970',
                        'Short tour': '#6255A4',
                        'VTS':        '#5C7CB0',
                        'Other JV bus':   '#6DB1B3',
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
                        'Camp Denali/North Face Lodge':  '#F4B6BB',
                        'Shuttle TRN':                   '#A85C5E',
                        'Camper TRN':                    '#AF8252',
                        'Other TRN':                     '#DBD68C',
                        'Tundra Wilderness Tour TRN':    '#5B5E88',
                        'Denali Natural History Tour TRN': '#7681A6',
                        'Kantishna Experience TRN':      '#A5CEDD',
                        'Denali Backcountry Lodge TRN':  '#624C70',
                        'Kantishna Roadhouse TRN':       '#AB5C96',
                        'McKinley Gold Camp TRN':        '#E39ABF',
                        'Camp Denali/North Face Lodge TRN':'#F3E0E1'},
          'pov':       {'Researchers':   '#B24D4E',
                        'Photographers': '#587C97',
                        'NPS employees': '#639562',
                        'Inholders':     '#89648F',
                        'Tek campers':   '#BF7F3E',
                        'Other':         '#CDCB62'},
          'nps':        {'Administration': '#723C7D',
                         'Concessions': '#779F84',
                         'Interpretation': '#875E4D',
                         'Maintenance-BU': '#82142B',
                         'Maintenance-Roads': '#B43234',
                         'Maintenance-Support': '#CB7F2C',
                         'Maintenance-Trails':  '#E8DF60',
                         'Natural-Cultural Resources': '#4D766F',
                         'Planning': '#3E5297',
                         "Superintendent's Office": '#6790BB',
                         'VRP Rangers': '#C289BC',
                         'Other': '#8F8E8E'},
          'bikes':      {'cyclists': '#587C97'},
          'total':      {0: '#587C97'}
          }

DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'

FORMAT_STRS = {'day': '_%Y_%m_%d',
               'month': '_%Y_%m',
               'year': '_%Y',
               'hour': '_%Y_%m_%d_%H',
               'halfhour': '_%Y_%m_%d_%H_%M',
               'anniversary day': '_%m_%d',
               'anniversary month': '%b'
               }

def get_date_range(start_date, end_date, date_format='%Y-%m-%d %H:%M:%S', summarize_by='day'):

    FREQ_STRS = {'day':         'D',
                 'month':       'MS',
                 'year':        'Y',
                 'hour':        'H',
                 'halfhour':    '30min'
                 }

    # Even though we could pass a datetime object here in some cases, when called from functions other than main(),
    #   we have the date str not datetime and we don't necessarily know the format. So just convert to datetime here
    date_range = pd.date_range(datetime.strptime(start_date, date_format),
                               datetime.strptime(end_date, date_format),
                               freq=FREQ_STRS[summarize_by]
                               )

    # For months and years, need to add 1
    if summarize_by == 'year':
        start_year = datetime.strptime(start_date, date_format).year
        if start_year == datetime.strptime(end_date, date_format).year:
            date_range = pd.date_range(datetime.strptime(str(start_year), '%Y'),
                                       datetime.strptime(str(start_year + 1), '%Y'),
                                       freq='Y')
        date_range = pd.to_datetime(pd.concat([pd.Series(date_range - pd.offsets.YearBegin()),
                                               pd.Series(date_range + pd.offsets.YearBegin())])
                                    .unique()
                                    )
    elif summarize_by == 'month':
        '''############# CLEAN THIS UP ##############'''
        start_datetime = datetime.strptime(start_date, date_format).replace(day=1)
        if start_datetime.month == datetime.strptime(end_date, date_format).month:
            date_range = pd.date_range(start_datetime,
                                       start_datetime + rd.relativedelta(months=1),
                                       freq=pd.DateOffset(months=1))
        else:
            date_range = pd.date_range(start_datetime,
                                       datetime.strptime(end_date, date_format),
                                       freq=FREQ_STRS[summarize_by]
                                       )

    # For day, hour, halfhour, clip the last one because it rolls over into the next interval
    else:
        date_range = date_range[:-1]

    return date_range


def filter_output_fields(category_sql, engine, output_fields):

    with engine.connect() as conn, conn.begin():
        actual_fields = pd.read_sql(category_sql, conn)

    field_column_name = actual_fields.columns[0]
    matches = pd.merge(pd.DataFrame(output_fields, columns=['field_name']), actual_fields,
                       left_index=True, right_on=field_column_name, how='inner')

    return matches.set_index(field_column_name).sort_index().squeeze() #type: pd.Series


def get_output_field_names(date_range, summarize_by, filter_sql=None, engine=None, gmp_dates=None):

    # Format of columns to write CSVs to
    out_format = FORMAT_STRS[summarize_by]
    names = date_range.strftime(out_format).str.lower()
    # index is in the format that postgres will spit out for timestamps (i.e., the columns for query results)
    index = date_range.strftime(DATETIME_FORMAT)
    names = pd.Series(names, index=index)

    #keys = pd.to_datetime(names, format=out_format).strftime(in_format).to_series().apply(in_function)

    # If a filter sql query and a DB connection were given, return only names that exist for the given sql query
    if filter_sql and engine:
        names = filter_output_fields(filter_sql, engine, names)

    if gmp_dates:
        gmp_dates = np.array(zip(*gmp_dates)).flatten()[1:-1]
        if len(gmp_dates) > 1:
            date_ranges = [pd.date_range(end + pd.DateOffset(days=1), start, freq=date_range.freq).to_series()[:-1] for end, start in zip(gmp_dates[::2], gmp_dates[1::2])]
            exclude_dates = pd.concat(date_ranges).dt.strftime(DATETIME_FORMAT)
            names = names.drop(exclude_dates)

    return names


def get_x_labels(date_range, summarize_by):

    LABEL_FORMAT_STRS = {'day':       '%m/%d/%y',
                         'month':     '%b %Y',
                         'year':      '%Y',
                         'hour':      '%H:%M',
                         'halfhour':  '%H:%M',
                         'anniversary day': '%m/%d',
                         'anniversary month': '%b'
                         }
    names = date_range.strftime(LABEL_FORMAT_STRS[summarize_by]).to_series()#.unique().to_series()
    names.index = np.arange(len(names))

    return names


def get_gmp_date_clause(start_datetime, end_datetime):
    """
    Return an SQL statement that specifies GMP date criteria for each year between the start and
    end dates specified. GMP date criteria are the Saturday before Memorial Day and
    min(2nd thursday of September, September 15)
    """

    # Define a custom observance rule for the end date of the GMP period
    def thursday_or_15th(dt):
        """
        If the 2nd thursday after Labor Day is before the 15th, return that.
        Otheriwse, return the 15th
        """
        second_thursday = holiday.Holiday("2nd Thursday", month=9, day=1, offset=[holiday.USLaborDay.offset,
                                                                                  pd.DateOffset(weekday=holiday.TH(2))])
        this_second_thursday = second_thursday.dates(datetime(dt.year, 1, 1), datetime(dt.year, 12, 31))[0]
        this_15th = datetime(dt.year, 9, 15)

        return min(this_15th, this_second_thursday)

    start_holiday = holiday.Holiday("GMP start", month=5, day=31, offset=[holiday.USMemorialDay.offset,
                                                                          pd.DateOffset(weekday=holiday.SA(-1))]
                                    )
    end_holiday = holiday.Holiday("GMP end", month=9, day=15, observance=thursday_or_15th)

    years = xrange(start_datetime.year,
                   end_datetime.year + 1)
    starts = start_holiday.dates(datetime(years[0], 1, 1), datetime(years[-1], 12, 31))
    ends = end_holiday.dates(datetime(years[0], 1, 1), datetime(years[-1], 12, 31))

    btw_stmts = []
    for gmp_start, gmp_end in zip(starts, ends):
        btw_stmts.append("(datetime BETWEEN '{start}' AND '{end}') "
                         .format(start=gmp_start.strftime('%Y-%m-%d'),
                                 end=gmp_end.strftime('%Y-%m-%d'))
                         )
    sql = ' AND (%s) ' % ('OR '.join(btw_stmts))

    return sql, starts.min().to_pydatetime(), ends.max().to_pydatetime()


def get_gmp_dates(start_datetime, end_datetime):
    """
    Return an SQL statement that specifies GMP date criteria for each year between the start and
    end dates specified. GMP date criteria are the Saturday before Memorial Day and
    min(2nd thursday of September, September 15)
    """

    # Define a custom observance rule for the end date of the GMP period
    def thursday_or_15th(dt):
        """
        If the 2nd thursday after Labor Day is before the 15th, return that.
        Otheriwse, return the 15th
        """
        second_thursday = holiday.Holiday("2nd Thursday", month=9, day=1, offset=[holiday.USLaborDay.offset,
                                                                                  pd.DateOffset(weekday=holiday.TH(2))])
        this_second_thursday = second_thursday.dates(datetime(dt.year, 1, 1), datetime(dt.year, 12, 31))[0]
        this_15th = datetime(dt.year, 9, 15)

        return min(this_15th, this_second_thursday)

    start_holiday = holiday.Holiday("GMP start", month=5, day=31, offset=[holiday.USMemorialDay.offset,
                                                                          pd.DateOffset(weekday=holiday.SA(-1))]
                                    )
    end_holiday = holiday.Holiday("GMP end", month=9, day=15, observance=thursday_or_15th)

    years = xrange(start_datetime.year,
                   end_datetime.year + 1)
    starts = start_holiday.dates(datetime(years[0], 1, 1), datetime(years[-1], 12, 31))
    ends = end_holiday.dates(datetime(years[0], 1, 1), datetime(years[-1], 12, 31))

    return starts, ends



def filter_data_by_category(data, category_filter):

    # Check if the filter string has any special characters (except '_', '/' ,'-', ',') in it. If so,
    #   assume it's a regex
    if re.search(r'([^a-zA-Z_/\-,\s])', category_filter):
        category_filter = '|'.join([c.strip() for c in category_filter.split(',')])
        mask = ~pd.Series(map(re.match, [category_filter] * len(data), data.index)).astype(bool)
    # Otherwise, just match the strings exactly
    else:
        values = [f.strip() for f in category_filter.split(',')]
        mask = ~data.index.isin(values)
    data.drop(data.index[mask], inplace=True)

    return data


def query_all_vehicles(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', drop_null=False, get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field='datetime', start_time=None, end_time=None):

    ########## Query buses
    buses, training_buses, buses_sql = query_buses(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, is_subquery=True, other_criteria=other_criteria, get_totals=get_totals, value_filter=value_filter, summary_stat=summary_stat, summary_field=summary_field, start_time=start_time, end_time=end_time)
    buses = buses.add(training_buses, fill_value=0)

    # Query GOVs
    #simple_output_fields = get_output_field_names(date_range, summarize_by)
    where_clause = "datetime BETWEEN '{start_date}' AND '{end_date}' " \
                   "AND destination NOT LIKE 'Primrose%%' "\
        .format(start_date=start_date, end_date=end_date) \
        + other_criteria
    govs, gov_sql = query.simple_query_by_datetime(engine, 'nps_vehicles', field_names=field_names['nps_vehicles'], other_criteria=where_clause, summarize_by=summarize_by, output_fields=output_fields, get_totals=get_totals, summary_stat=summary_stat, summary_field=summary_field, return_sql=True, start_time=start_time, end_time=end_time)
    govs.index = ['GOV']

    # POVs
    povs, pov_sql = query_pov(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, other_criteria=other_criteria, value_filter=value_filter, summary_stat=summary_stat, summary_field=summary_field, start_time=start_time, end_time=end_time)

    if len(povs.columns) > 0:
        povs.loc['POV'] = povs.sum(axis=0)
        povs.drop([i for i in povs.index if i != 'POV'], inplace=True)
    else:
        povs = pd.DataFrame(columns=buses.columns)

    data = pd.concat([buses, govs, povs], sort=False)

    if sort_order:
        data = data.reindex(sort_order)

    if category_filter:
        data = filter_data_by_category(data, category_filter)

    return data, buses_sql + [gov_sql] + pov_sql


def query_buses(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, is_subquery=False, sort_order=None, other_criteria='', get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field='datetime', start_time=None, end_time=None):

    if value_filter:
        values = ["'%s'" % v for v in value_filter.split(',')]
        other_criteria += " AND bus_type IN (%s) " % ','.join(values)

    ########## Query non-training buses
    bus_other_criteria = "is_training = ''false'' " \
                     "AND datetime BETWEEN ''{start_date}'' AND ''{end_date}'' "\
                     .format(start_date=start_date, end_date=end_date) \
                     + other_criteria.replace("'", "''")

    kwargs = {'other_criteria': bus_other_criteria,
              'field_names': field_names['buses'],
              'summarize_by': summarize_by,
              'filter_fields': True
              }

    # If this function is being called within query_all_vehicles(), set the names to aggregate. If this function
    #   is being called as just a query of buses, don't aggregate at all so no need to set dissolve_names
    if is_subquery:
        bus_names = {'VTS': ['Shuttle', 'Camper'],
                     'Other JV bus': ['Other'],
                     'Long tour': ['Kantishna Experience', 'Eielson Excursion',
                                   'Tundra Wilderness Tour', 'Windows Into Wilderness'],
                     'Short tour': ['Denali Natural History Tour'],
                     'Lodge bus': ['Kantishna Roadhouse', 'Denali Backcountry Lodge',
                                   'Camp Denali/North Face Lodge']
                     }
        kwargs['dissolve_names'] = bus_names

    kwargs['output_fields'] = output_fields

    buses, buses_sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type', get_totals=get_totals, summary_stat=summary_stat, return_sql=True, summary_field=summary_field, start_time=start_time, end_time=end_time, **kwargs)

    ######### Query training buses
    trn_other_criteria = "is_training " \
                         "AND datetime BETWEEN ''{start_date}'' AND ''{end_date}'' " \
                        .format(start_date=start_date, end_date=end_date) \
                        + other_criteria.replace("'", "''")

    kwargs['other_criteria'] = trn_other_criteria

    if is_subquery:
        kwargs['dissolve_names'] = {'Other JV bus': ['Shuttle', 'Camper', 'Kantishna Experience',
                                                 'Eielson Excursion', 'Tundra Wilderness Tour',
                                                 'Windows Into Wilderness', 'Denali Natural History Tour', 'Other'],
                                    'Lodge bus': ['Kantishna Roadhouse', 'Denali Backcountry Lodge',
                                                  'Camp Denali/North Face Lodge']
                                    }

    # Get appropriate field names as with non-training buses
    training_buses, trn_sql = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type', get_totals=get_totals, summary_stat=summary_stat, return_sql=True, summary_field=summary_field, start_time=start_time, end_time=end_time, **kwargs)



    if is_subquery:
        return buses, training_buses, [buses_sql, trn_sql]

    training_buses.index = training_buses.index + ' TRN'

    data = pd.concat([buses, training_buses], sort=False)
    if sort_order:
        data = data.reindex(sort_order)

    if category_filter:
        data = filter_data_by_category(data, category_filter)

    return data, [buses_sql, trn_sql]


def query_total(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field='datetime', start_time=None, end_time=None):

    data = query_all_vehicles(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, other_criteria=other_criteria, value_filter=value_filter, category_filter=category_filter, summary_stat=summary_stat, summary_field=summary_field, start_time=start_time, end_time=end_time)
    totals = pd.DataFrame(data.sum(axis=0)).T

    return totals


def query_nps(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field=None, start_time=None, end_time=None):

    if value_filter:
        values = ["'%s'" % v for v in value_filter.split(',')]
        other_criteria += " AND work_group IN (%s) " % ','.join(values)

    other_criteria = "datetime BETWEEN ''{start_date}'' AND ''{end_date}'' "\
                        .format(start_date=start_date, end_date=end_date) \
                        + other_criteria.replace("'", "''")

    #output_fields = get_output_field_names(date_range, summarize_by)
    data, sql = query.crosstab_query_by_datetime(engine, 'nps_vehicles', start_date, end_date, 'work_group',
                                            field_names=field_names['nps_vehicles'], other_criteria=other_criteria,
                                            summarize_by=summarize_by, output_fields=output_fields, filter_fields=True,
                                            get_totals=get_totals, summary_stat=summary_stat, summary_field=summary_field, return_sql=True, start_time=start_time, end_time=end_time)

    if sort_order:
        data = data.reindex(sort_order)

    if category_filter:
        data = filter_data_by_category(data, category_filter)

    return data, [sql]


def query_pov(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field='datetime', start_time=None, end_time=None):

    OTHER_CRITERIA = {'nps_employee':   "AND destination IN ('Toklat', 'Wonder Lake') ",
                      'other_employee': "AND destination NOT IN ('Toklat', 'Wonder Lake') ",
                      'researcher':     "AND destination NOT LIKE 'Primrose%%' AND "
                                        "approved_type = 'Researcher' ",
                      'other_approved': "AND destination NOT LIKE 'Primrose%%' AND "
                                        "approved_type <> 'Researcher' "
                      }

    sql_queries = [
        ('inholders',           'Inholders',        ''),
        ('employee_vehicles',   'NPS employees',    OTHER_CRITERIA['nps_employee']),
        ('employee_vehicles',   'Other',            OTHER_CRITERIA['other_employee']),
        ('photographers',       'Photographers',    ''),
        ('nps_approved',        'Researchers',      OTHER_CRITERIA['researcher']),
        ('nps_approved',        'Other',            OTHER_CRITERIA['other_approved']),
        ('accessibility',       'Other',            ''),
        ('subsistence',         'Other',            ''),
        ('tek_campers',         'Tek campers',      '')
    ]

    all_data = []
    sql_statements = []
    for table_name, print_name, criteria in sql_queries:
        data, sql = query.simple_query_by_datetime(engine, table_name, field_names=field_names[table_name],
                                              summarize_by=summarize_by, output_fields=output_fields,
                                              other_criteria="datetime BETWEEN '%s' AND '%s' " %
                                                             (start_date, end_date) + criteria + other_criteria,
                                              get_totals=get_totals, summary_stat=summary_stat, summary_field=summary_field, return_sql=True, start_time=start_time, end_time=end_time
                                              )

        data.index = [table_name]
        all_data.append(data)
        sql_statements.append(sql)

    data = pd.concat(all_data, sort=False)

    data = data.groupby(data.index).sum(axis=0)

    if sort_order:
        data = data.reindex(sort_order)

    if category_filter:
        data = filter_data_by_category(data, category_filter)

    return data, sql_statements


def query_bikes(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', get_totals=False, value_filter='', category_filter='', summary_stat='COUNT', summary_field='datetime', start_time=None, end_time=None):

    data, sql = query.simple_query_by_datetime(engine, 'cyclists', field_names=field_names['cyclists'],
                                          summarize_by=summarize_by, output_fields=output_fields,
                                          other_criteria="datetime BETWEEN '%s' AND '%s' " %
                                                         (start_date, end_date) + other_criteria,
                                               summary_stat=summary_stat, summary_field=summary_field, return_sql=True, start_time=start_time, end_time=end_time
                                          )

    return data, [sql]



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

    return data, cols[drop_inds]


def show_legend(legend_title, label_suffix=None):
    ax = plt.gca()
    handles, labels = ax.get_legend_handles_labels()
    if label_suffix:
        labels = [l + label_suffix[l] for l in labels]
    n_labels = len(np.unique(labels)) - 1 # stackplots produce duplicate handles/labels
    legend = plt.legend(handles[n_labels::-1], labels[n_labels::-1], bbox_to_anchor=(1.04, 0),
                        loc='lower left', title=legend_title, frameon=False)
    legend._legend_box.align = 'left'
    max_label_length = max(map(len, labels))
    proportional_adjustment = (0.1 * max_label_length / 30.0)  # type: float
    right_adjustment = 0.75 - proportional_adjustment
    plt.subplots_adjust(right=right_adjustment, bottom=.15)  # make room for legend and x labels


def plot_bar(all_data, x_labels, out_img, plot_type='stacked bar', vehicle_limits=None, title=None, legend_title='', max_xticks=20, colors={}, plot_totals=False, show_percents=False, remove_gaps=False):

    if plot_totals:
        all_data.loc['Total'] = all_data.sum(axis=0)

    n_vehicles, n_dates = all_data.shape
    if remove_gaps:
        spacing_factor = int(n_vehicles) if plot_type == 'grouped bar' else 1
    else:
        spacing_factor = int(n_vehicles * 1.3) if plot_type == 'grouped bar' else 2
    bar_width = 1

    ax = plt.gca()
    date_index = np.arange(n_dates) * spacing_factor
    grouped_index = np.arange(n_vehicles) - n_vehicles / 2  # /2 centers bar for grouped bar chart
    bar_index = np.arange(n_vehicles) * spacing_factor

    # PLot horizontal lines showing max concessionaire buses and total vehicles per day or year
    if vehicle_limits:
        for y_value in vehicle_limits:
            ax.plot([-date_index.max() * 2, date_index.max() * 2],
                    [y_value, y_value], '--', alpha=0.3, color='0.3',
                    zorder=100)# zorder = 2 because seaborn grid lines will plot on top if 0 or 1

    last_top = np.zeros(n_dates)
    for i, (vehicle_type, data) in enumerate(all_data.iterrows()):
        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        # If the bars are grouped, make sure they're offset. If they're stacked or just regular bars, just pass
        #   x indices that are evenly spaced
        if plot_type == 'stacked bar':
            x_inds = date_index
        elif plot_type == 'grouped bar':
            x_inds = date_index - bar_width * grouped_index[i]
        elif plot_type == 'bar':
            if n_dates == 1:
                x_inds = [bar_index[i]]
            else:
                x_inds = date_index

        ax.bar(x_inds, data, bar_width, bottom=last_top, label=vehicle_type, zorder=i + 3, color=color)

        if show_percents:
            try:
                percents = data / all_data.sum(axis=0) * 100
            except ZeroDivisionError:
                percents = np.zeros(len(data))
            percent_y = last_top + data/2 # center them in each bar

            for i in range(len(x_inds)):
                ax.text(x_inds[i], percent_y[i], '%d%%' % percents.iloc[i], color='white', fontsize=8,
                        horizontalalignment='center', verticalalignment='center',
                        zorder=i + 100)# for some reason, zorder has to be way higher to actually plot on top

        last_top += data if plot_type == 'stacked bar' else 0

    x_tick_inds = bar_index if n_dates == 1 else date_index

    if len(x_labels) > 1:
        x_tick_interval = 1 if n_dates == 1 else max(1, int(round(n_dates/float(max_xticks))))
        if plot_type == 'bar' and n_dates == 1:
            x_labels = pd.Series(all_data.index, x_labels.index) # The vehicle types
        plt.xticks(x_tick_inds[::x_tick_interval], x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')
    else:
        plt.xticks([], []) # Don't plot any labels

    # If adding horizonal lines, make sure their values are noted on the y axis. Otherwise, just
    #   use the default ticks
    #if vehicle_limits:
        #plt.yticks(np.unique((list(ax.get_yticks()) + vehicle_limits)))

    # Set enough space on either end of the plot
    if plot_type == 'grouped bar':
        plt.xlim([-n_vehicles / 2, x_tick_inds.max() + n_vehicles / 2 + 1])
    else:
        plt.xlim([-1, x_tick_inds.max() + 1])

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
        show_legend(legend_title)

    _, extension = os.path.splitext(out_img)
    this_img = out_img.replace(extension, '_{tag}{ext}'.format(tag=plot_type.replace(' ', '_'), ext=extension))
    plt.savefig(this_img, dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop


def plot_line(all_data, x_labels, out_img, vehicle_limits=None, title=None, legend_title=None, max_xticks=20, colors={}, plot_type='line', show_stats=False, plot_totals=False):

    if plot_totals:
        all_data.loc['Total'] = all_data.sum(axis=0)

    n_vehicles, n_dates = all_data.shape
    stats_labels = {}
    data_stats = []

    if vehicle_limits:
        for y_value in vehicle_limits:
            plt.plot([-n_dates * 2, n_dates * 2],
                    [y_value, y_value], '--', alpha=0.3, color='0.3',
                    zorder=100)

    for vehicle_type, counts in all_data.iterrows():
        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        stats_label = ''  # default to empty str
        if plot_type == 'best fit':
            x = np.arange(n_dates)
            slope, intercept = np.polyfit(x, counts, 1)
            x_inds = np.array([0, n_dates])
            y_vals = x_inds * slope + intercept

            plt.plot(x_inds, y_vals, '-', color=color, label=vehicle_type)
            plt.scatter(x, counts, color=color, alpha=0.5, label='')

            if show_stats:
                r, p = stats.pearsonr(counts, x * slope + intercept)
                stats_label = r' (slope = %.1f, $\it{r} = %.2f)$' % (slope, r)
                data_stats.append({'slope': slope, 'r': r})
        elif plot_type == 'stacked area':
            colors = pd.Series(colors).reindex(all_data.index)
            plt.stackplot(np.arange(n_dates), all_data, labels=all_data.index, colors=colors)
        else:
            plt.plot(xrange(n_dates), counts, '-', color=color, label=vehicle_type)
        stats_labels[vehicle_type] = stats_label

    x_tick_interval = max(1, int(round(n_dates / float(max_xticks))))
    plt.xticks(xrange(0, n_dates, x_tick_interval), x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')

    if not title:
        title = 'Vehicles past Savage River, %s - %s' % (x_labels.iloc[0], x_labels.iloc[-1])
    plt.title(title)

    if n_vehicles > 1:
        show_legend(legend_title, label_suffix=stats_labels)

    max_vehicle_limit = max(vehicle_limits) if vehicle_limits else 0
    yticks, _ = plt.yticks()

    y_tick_interval = yticks[1] - yticks[0]
    plt.ylim([0, max(max_vehicle_limit, all_data.values.max()) + y_tick_interval/2.0])
    if plot_type == 'stacked area':
        plt.xlim([0, n_dates])
        plt.ylim([0, max(max_vehicle_limit, all_data.sum(axis=0).max()) + y_tick_interval / 2.0])
    else:
        plt.ylim([0, max(max_vehicle_limit, all_data.values.max()) + y_tick_interval / 2.0])
    sns.despine()

    # Grouped bar charts are too small to read at the default width so widen if bars are grouped
    figure = plt.gcf()
    width = figure.get_figwidth()
    # Make sure the width scale is between 1 and 3
    width_scale = max(1, min(n_dates/float(max_xticks), 3))
    figure.set_figwidth(width * width_scale)

    _, extension = os.path.splitext(out_img)
    this_img = out_img.replace(extension, '_{tag}{ext}'.format(tag=plot_type.replace(' ', '_'), ext=extension))
    plt.savefig(this_img, dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop

    if data_stats:
        data_stats = pd.DataFrame(data_stats, index=all_data.index)
        data_stats.to_csv(this_img.replace(extension, '_stats.csv'))


def aggregate(data, summarize_by, aggregate_by, summary_stat, output_fields):

    summary_functions = {'COUNT': np.sum,
                         'SUM': np.sum,
                         'AVG': np.mean,
                         'MIN': np.min,
                         'MAX': np.max,
                         'STDDEV': np.std}
    #agg_strs = pd.to_datetime(output_fields.index).strftime(FORMAT_STRS[aggregate_by])
    agg_strs = pd.to_datetime(data.columns, format=FORMAT_STRS[summarize_by]).strftime(FORMAT_STRS[aggregate_by])
    data_t = data.T
    data_t['agg_str'] = agg_strs.values
    data = data_t.groupby('agg_str').aggregate(summary_functions[summary_stat.upper()]).T
    new_datetimes = pd.to_datetime(data.columns, format=FORMAT_STRS[aggregate_by])
    new_labels = pd.Series(get_x_labels(new_datetimes, aggregate_by).sort_values().unique(),
                           index=data.columns.sort_values())

    return data, new_labels


def write_metadata(out_csv, queries, summarize_by, summary_field, summary_stat, agg_stat, aggregate_by, start_date, end_date, sql_values_filter, category_filter):

    QUERY_DESCRIPTIONS = {'summary':    'all vehicles aggregated in broad categories',
                          'buses':      'buses by each type found in the "bus_type" column of the "buses" table',
                          'nps':        'NPS vehicles by work group',
                          'pov':        'all private vehicles by type',
                          'bikes':      'All byciclists',
                          'total':      'total of all vehicles'}
    summary_functions = {'COUNT': 'count',
                         'SUM': 'sum',
                         'AVG': 'average',
                         'MIN': 'minumum',
                         'MAX': 'maximum',
                         'STDDEV': 'standard deviation'}

    command = 'python ' + subprocess.list2cmdline(sys.argv)

    descr = "This folder contains queried data and derived plots from the Savage Box database. Data were summarized " \
            "by {agg_stat}{summary_stat} of {summary_field} by {summarize_by} for dates between {start} and {end}. "\
        .format(agg_stat='the %s of the %s per ' % (summary_functions[agg_stat.upper()], aggregate_by) if agg_stat else '',
                summarize_by=summarize_by,
                summary_stat=summary_functions[summary_stat.upper()],
                summary_field=summary_field,
                start=start_date,
                end=end_date)
    descr += "Queries run include:\n\t-" + "\n\t-".join([q + ": " + QUERY_DESCRIPTIONS[q] for q in queries])

    options_desc = "\n\nAdditional options specified:\n\t-"
    options = []
    if sql_values_filter:
        options.append("SQL queries were limited to only values in the pivot field of pertinent tables per query that "
                       "matched one of the following:\n\t\t-" + "\n\t\t-".join(sql_values_filter.split(',')))
    if category_filter:
        options.append("once SQL queries were run and data from multiple queries were compiled, results were limited to"
                       " only categories that matched one of the following by direct comparison or regular expression:"
                       "\n\t\t-" + "\n\t\t-".join(category_filter.split(',')))
    if '--time_range' in command:
        options.append("SQL queries were limited to only records where the time of day was between %s" % 
                       [arg for arg in sys.argv if arg.startswith('--time_range')][0].replace('--time_range=', ''))
    if '--write_sql' in command or ' -w' in command:
        options.append("SQL statements generated by each query were written to a text file with the "
                       "same name as each query's csv file and '_sql.txt' at the end")
    if '--plot_vehicle_limits' in command or ' -p' in command:
        options.append("queries were limited to only observations that occurred between the start and end of "
                       "the GMP allocation period (Saturday before Memorial Day and either the 2nd Thursday "
                       "in September or September 15, whichever came first)")
    if '--strip_data' in command or ' -s' in command:
        options.append("the first and last sets of consecutive null dates/times were removed")
    if '--use_gmp_dates' in command or ' -g' in command:
        options.append("in addition to querying only dates between %s-%s, any records outside the GMP"
                       " allocation period (5/20-9/15) were excluded from the query" % (start_date, end_date))
    if '--show_stats' in command or ' -x' in command:
        options.append("relevant stats for the plot type were displayed in the legend")
    if '--plot_totals' in command or ' -t' in command:
        options.append("totals were plotted for all vehicle types")
    if '--show_percents' in command or ' -c' in command:
        options.append("percents of total vehicles per date/time were drawn on bars for bar charts")
    if '--remove_gaps' in command or ' -r' in command:
        options.append("gaps between bars in bar charts were removed")
    if '--drop_null' in command or ' -d' in command:
        options.append("dates/times without any data were removed from plots and the output CSV(s)")
    if '--white_background' in command or ' -b' in command:
        options.append("plots were made with the default Seaborn style (white background rather than gray)")

    if options:
        options_desc += "\n\t-".join(options)
        descr += options_desc

    datestamp = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    msg = descr + \
          "\n\nFor questions, please contact Sam Hooper at samuel_hooper@nps.gov\n" \
          "\nSCRIPT: {script}" \
          "\nTIME PROCESSED: {datestamp}" \
          "\nCOMMAND: {command}"\
              .format(script=__file__,
                      datestamp=datestamp,
                      command=command)

    readme_path = out_csv.replace('.csv', '_README.txt')
    with open(readme_path, 'w') as readme:
        readme.write(msg)


def main(connection_txt, start_date, end_date, out_dir=None, out_csv=None, plot_types='stacked bar', summarize_by='day', queries=None, strip_data=False, plot_vehicle_limits=False, use_gmp_dates=False, show_stats=False, plot_totals=False, show_percents=False, max_queried_columns=1599, drop_null=False, remove_gaps=False, sql_values_filter=None, category_filter=None, write_sql=False, summary_stat=None, summary_field=None, white_background=False, time_range=None, plot_extension=None, aggregate_by=None):

    QUERY_FUNCTIONS = {'summary':   query_all_vehicles,
                       'buses':     query_buses,
                       'pov':       query_pov,
                       'nps':       query_nps,
                       'bikes':     query_bikes,
                       'total':     query_total}

    TITLE_PREFIXES = {'summary':    'Vehicles',
                      'buses':      'Buses',
                      'nps':        'NPS vehicles',
                      'pov':        'Private vehicles',
                      'bikes':      'Bikes',
                      'total':      'Total vehicles'}

    sns.set_context('paper')
    if not white_background:
        sns.set_style('darkgrid')

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.flush()

    # If nothing is passed, assume that all queries should be run
    if not queries:
        queries = QUERY_FUNCTIONS.keys()
    # Otherwise it should be a comma-separated list
    else:
        queries = [q.strip().lower() for q in queries.split(',')]
    valid_query_strings = [q in QUERY_FUNCTIONS.keys() for q in queries]
    if not any(valid_query_strings):
        warnings.warn('No valid query type string found in queries: %s. All queries '
                             'will be run.' % ', '.join(queries), RuntimeWarning)

    # Split plot types (passed as comma-separated string) into a list
    if plot_types:
        plot_types = [t.strip().lower().replace('_', ' ') for t in plot_types.split(',')]
        # Check if any recognizable strings are in plot_types
        valid_strings = [s in ['stacked bar', 'grouped bar', 'line', 'best fit', 'bar', 'stacked area', ''] for s in plot_types]
        if not any(valid_strings):
            warnings.warn('No valid plot type string found in plot_types: %s. No plots will be made.'
                          % ', '.join(plot_types))

    if plot_vehicle_limits and summarize_by not in ['day', 'year']:
        warnings.warn("The '--plot_vehicle_limits' flag was passed but summarize_by given was not 'day' or 'year', so the"
                      " vehicle limits won't make any sense. Try the command 'python count_vehicles_by_type.py --help'"
                      " information on valid parameters")

    if sql_values_filter:
        sql_values_filter = ','.join([v.strip() for v in sql_values_filter.split(',')])  # stip spaces before/after each value
        if len(queries) > 1:
            warnings.warn("value filters of %s were given, but these might not be relevant to all queries specified"
                          " (%s)" % (sql_values_filter, ','.join(queries)))
    if category_filter and len(queries) > 1:
        # Don't need to split category filter because filter_data_by_category() handles the string
        warnings.warn("value filters of %s were given, but these might not be relevant to all queries specified"
                      " (%s)" % (category_filter, ','.join(queries)))

    # reformat dates for postgres (yyyy-mm-dd), assuming format mm/dd/yyyy
    try:
        start_datetime = datetime.strptime(start_date, '%m/%d/%Y')
        end_datetime = datetime.strptime(end_date, '%m/%d/%Y') +\
                       rd.relativedelta(days=1) # add 1 day because BETWEEN looks for dates before end date
    except:
        raise ValueError('start and end dates must be in format mm/dd/YYYY')

    # Check format of start time and end time if time_range given
    if time_range:
        try:
            start_time, end_time = time_range.split('-') #will raise value error if split() isn't len() == 2
        except:
            raise ValueError("time_range must be in the format start_time-end_time")
        try:
            datetime.strptime(start_time, '%H:%M')
            datetime.strptime(end_time, '%H:%M')
        except:
            raise TypeError("start time and end time must be in format hh:mm")
    else:
        start_time, end_time = None, None


    # If the --use_gmp_dates flag was passed, add additional criteria to makes sure dates are at least constrained to the GMP allocation period. Also make sure the date range is appropriately clipped.
    gmp_date_criteria = ''
    gmp_dates = []
    if use_gmp_dates:
        #gmp_date_criteria, min_gmp, max_gmp = get_gmp_date_clause(start_datetime, end_datetime)
        gmp_starts, gmp_ends = get_gmp_dates(start_datetime, end_datetime)
        gmp_dates = [gmp_starts, gmp_ends]
        btw_stmts = []
        for gmp_start, gmp_end in zip(gmp_starts, gmp_ends):
            btw_stmts.append("(datetime BETWEEN '{start}' AND '{end}') "
                             .format(start=gmp_start.strftime('%Y-%m-%d'),
                                     end=gmp_end.strftime('%Y-%m-%d'))
                             )
        gmp_date_criteria = ' AND (%s) ' % ('OR '.join(btw_stmts))
        start_datetime = max(start_datetime, gmp_starts.min().to_pydatetime())
        end_datetime = min(end_datetime, gmp_ends.max().to_pydatetime())
    start_date = start_datetime.strftime(DATETIME_FORMAT)
    end_date = end_datetime.strftime(DATETIME_FORMAT)

    # Make a generic csv path if necessary
    if out_dir:
        # if both out_csv and out_dir are given, still just use out_csv. If just out_dir, use an informative basename
        if not out_csv:
            basename = '.csv'
            if not os.path.isdir(out_dir):
                os.mkdir(out_dir)
            out_csv = os.path.join(out_dir, basename)
    elif not out_csv:
        # If we got here, neither out_dir nor out_csv were given so raise an error
        raise ValueError('Either out_csv or out_dir must be given')

    # Check that summary_stat is a valid (postgres) SQL function
    valid_stats = ['COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'STDDEV']
    if not summary_stat:
        summary_stat = 'COUNT'
    elif summary_stat.upper() not in valid_stats:
        raise ValueError('Summary stat "{}" is not valid. It must be one of the following: {}'
                         .format(summary_stat, ', '.join(valid_stats))
                         )
    agg_stat = ''
    if aggregate_by:
        agg_stat = summary_stat
        summary_stat = 'COUNT'

    if not summary_field:
        summary_field = 'datetime'

    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
    engine = query.connect_db(connection_txt)

    # Get field names that don't contain unique IDs
    field_names = query.query_field_names(engine)

    # Create output field names as a string
    date_range = get_date_range(start_date, end_date, summarize_by=summarize_by)
    output_fields = get_output_field_names(date_range, summarize_by, gmp_dates=gmp_dates)

    x_labels = get_x_labels(pd.to_datetime(output_fields.index), summarize_by)
    x_labels.index = output_fields

    # Loop through queries and make each plot (if there were any given) per query
    for query_name in queries:
        if query_name not in QUERY_FUNCTIONS:
            warnings.warn('Invalid query name found: "%s". Query names must be separated'
                          ' by a comma and be one of the following: %s' %
                          (query_name, ', '.join(QUERY_FUNCTIONS.keys())),
                          RuntimeWarning)
            queries.remove(query_name)
            continue

        query_function = QUERY_FUNCTIONS[query_name]

        # Process the query in chunks because PostgreSQL has a limit of 1600 columns in a query result,
        #   which a user-defined query could exceed
        n_dates = len(output_fields)
        chunk_inds = np.arange(0, n_dates, max_queried_columns) + max_queried_columns
        start_index = 0
        all_data = []
        sql_statements = []
        for i, index in enumerate(chunk_inds):
            index = min(index, n_dates)
            these_output_fields = output_fields.iloc[start_index : index]
            this_date_range = date_range[start_index : index]
            # If this is the last chunk, make sure the last date (used in SQL statements) is actually the last date of the range
            this_end_date = these_output_fields.index[-1] if i + 1 != len(chunk_inds) else end_date
            data, sql_stmts = query_function(these_output_fields, field_names, these_output_fields.index[0],
                                             this_end_date, this_date_range, summarize_by, engine,
                                             sort_order=SORT_ORDER[query_name], other_criteria=gmp_date_criteria,
                                             get_totals=False, value_filter=sql_values_filter,
                                             category_filter=category_filter, summary_stat=summary_stat,
                                             summary_field=summary_field, start_time=start_time, end_time=end_time)
            all_data.append(data)
            sql_statements.extend(sql_stmts)
            start_index = index
        data = pd.concat(all_data, axis=1)

        # Remove rows without any data
        data.fillna(0, inplace=True)
        data = data.loc[data.sum(axis=1) > 0]

        these_labels = x_labels.copy()

        # If stip_data is true, remove empty columns from edges of the data
        if strip_data:
            data, drop_inds = strip_dataframe(data)
            these_labels = these_labels.drop(drop_inds) #drop the same labels
        # Otherwise if drop_null isn't true, make sure all dates are included, even if they don't have any data
        elif not drop_null:
            data = data.reindex(columns=output_fields).fillna(0)

        if aggregate_by:
            data, these_labels = aggregate(data, summarize_by, aggregate_by, agg_stat, output_fields[output_fields.isin(data.columns)])

        #if not plot_totals:
        #data.drop('total', axis=1, inplace=True)
        data = data.reindex(columns=data.columns.sort_values())  # make sure they're in chronological order

        # If only 1 interval was found or given, drop the last label because it's extraneous
        if len(data.columns) == 1:
            these_labels = these_labels.iloc[[0]]

        if len(data.columns) != len(these_labels):
            warnings.warn("Some dates/times between {start} and {end} did not contain any data".format(start=start_date, end=end_date))

        # Make sure labels match up with the output columns
        data.drop(data.columns[~data.columns.isin(these_labels.index)], axis=1, inplace=True)
        these_labels = these_labels.reindex(data.columns)

        # Write csv to disk
        this_csv_path = os.path.join(out_dir,
                                     '{query_name}_{summary_stat}_by_{summarize_by}_{aggregate_by}{start_date}_{end_date}.csv'
                                     .format(query_name=query_name,
                                             summary_stat=agg_stat.lower() if aggregate_by else summary_stat.lower(),
                                             summarize_by=summarize_by,
                                             aggregate_by='per_' + aggregate_by.replace(' ','') + '_' if aggregate_by else '',
                                             start_date=start_datetime.strftime('%Y%m%d'),
                                             end_date=end_datetime.strftime('%Y%m%d')
                                             )
                                    )
        data.to_csv(this_csv_path)

        # PLot stuff
        vehicle_limits = []
        if plot_vehicle_limits:
            if query_name == 'summary':
                if summarize_by == 'day':
                    vehicle_limits = [91, 160]
                elif summarize_by == 'year':
                    vehicle_limits = [10512]
            elif query_name == 'buses' and summarize_by == 'day':
                vehicle_limits = [91]
            elif query_name == 'total':
                if summarize_by == 'day':
                    vehicle_limits = [160]
                elif summarize_by == 'year':
                    vehicle_limits = [10512]
            else:
                vehicle_limits = [] # doesn't make sense for other plots

        out_img = this_csv_path.replace('.csv', '.' + plot_extension.lstrip('.'))
        colors = COLORS[query_name]
        title = '{prefix} past Savage by {interval}, {start}-{end}'\
            .format(prefix=TITLE_PREFIXES[query_name], interval=summarize_by,
                    start=these_labels.iloc[0], end=these_labels.iloc[-1])
        if 'bar' in plot_types:
            plot_bar(data, these_labels, out_img, plot_type='bar', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'stacked bar' in plot_types:
            plot_bar(data, these_labels, out_img, plot_type='stacked bar', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'grouped bar' in plot_types:
            plot_bar(data, these_labels, out_img, plot_type='grouped bar', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'line' in plot_types:
            plot_line(data, these_labels, out_img, vehicle_limits=None, title=title, colors=colors, plot_totals=plot_totals)
        if 'best fit' in plot_types:
            plot_line(data, these_labels, out_img, vehicle_limits=None, title=title, colors=colors,
                      plot_type='best fit', show_stats=show_stats, plot_totals=plot_totals)
        if 'stacked area' in plot_types:
            plot_line(data, these_labels, out_img, vehicle_limits=vehicle_limits, title=title, colors=colors,
                      plot_type='stacked area', show_stats=show_stats, plot_totals=plot_totals)

        # Write all SQL statements to a text file
        if write_sql:
            out_sql_txt = this_csv_path.replace('.csv', '_sql.txt')
            break_str = '#' * 100
            with open(out_sql_txt, 'w') as f:
                for stmt in sql_statements:
                        f.write(stmt + '\n\n%s\n\n' % break_str)
                f.write('\n\n\n')

        write_metadata(this_csv_path, queries, summarize_by, summary_field, summary_stat, agg_stat, aggregate_by,
                       start_datetime.strftime('%m/%d/%y'), end_datetime.strftime('%m/%d/%y'),
                       sql_values_filter, category_filter)

    print '\nOutput files written to', out_dir


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    sys.exit(main(**args))
