'''
Query vehicle counts by day, month, or year for a specified date range

Usage:
    count_vehicles_by_type.py <connection_txt> <start_date> <end_date> (--out_dir=<str> | --out_csv=<str>) --summarize_by=<str> [--queries=<str>] [--plot_types=<str>] [--strip_data] [--plot_vehicle_limits] [--use_gmp_dates] [--show_stats] [--plot_totals] [--show_percents] [--remove_gaps] [--drop_null]

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
    --plot_types=<str>          Indicates the type of plot(s) to use. Options: 'line', 'grouped bar', or
                                'stacked bar' (the default)
    --summarize_by=<str>        String indicating the unit of time to use for summarization. Valid options are
                                'day' or 'doy', 'month', or 'year'
    --queries=<str>             Comma-separated list of data categories to query and plot. Valid options are
                                'summary', 'buses', 'nps', and 'pov'. If none specified, all queries are run.
    -s, --strip_data            Remove the first and last sets of consecutive null
                                from data (similar to str.strip()) before plotting and writing CSVs to disk.
                                Default is False.
    -p, --plot_vehicle_limits   Plot dashed lines indicating daily limits specified by the VMP (91 concessionaire buses
                                and 160 total vehicles). This option is only sensible to use with the 'doy' or 'day'
                                plot_type since these limits are by day. Default is False.
    -g, --use_gmp_dates         Limit query to GMP allocation period (5/20-9/15) in addition to start_date-end_date
    -x, --show_stats            Add relevant stats to labels in the legend. Only valid for 'best fit' plot type.
    -t, --plot_totals           Additionally show totals of all vehicle types. Not valid for 'total' plot type.
    -c, --show_percents         Draw percent of totals per interval on bars (only relevant for bar chart plot_types)
    -r, --remove_gaps           Plot bars without gaps between them
    -d, --drop_null             Remove any column (date/time) without any data for the given query
'''

import os, sys
import re
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from scipy import stats
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
          'total':      {0: '#587C97'}
          }
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'


def get_date_range(start_date, end_date, date_format='%Y-%m-%d %H:%M:%S', summarize_by='day'):

    FREQ_STRS = {'day':         'D',
                 'month':       'M',
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
        start_month = datetime.strptime(start_date, date_format).month
        if start_month == datetime.strptime(end_date, date_format).month:
            date_range = pd.date_range(datetime.strptime(str(start_month), '%m'),
                                       datetime.strptime(str(start_month + 1), '%m'),
                                       freq='M')
        date_range = pd.to_datetime(pd.concat([pd.Series(date_range - pd.offsets.MonthBegin()),
                                               pd.Series(date_range + pd.offsets.MonthBegin())])
                                    .unique()
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


def get_output_field_names(date_range, summarize_by, filter_sql=None, engine=None):

    '''FORMAT_STRS = {'doy':       ('%j', '%b_%d_%y', int),
                   'month':     ('%m', '%b', int),
                   'year':      ('%Y', '_%Y', int),
                   'hour':      ('%H', '_%H', int),
                   'halfhour':  ('%Y-%m-%d %H-%M-%S', '_%y_%m_%d_%H_%M',
                                 lambda x: pd.to_datetime(x, format='%Y-%m-%d %H-%M-%S')
                                 ) # just pd.to_datetime without a format doesn't keep minutes
                   }'''
    FORMAT_STRS = {'day':       '_%Y_%m_%d',
                   'month':     '_%y_%b',
                   'year':      '_%Y',
                   'hour':      '_%Y_%m_%d_%H',
                   'halfhour':  '_%Y_%m_%d_%H_%M'
                   }

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

    return names


def get_x_labels(date_range, summarize_by):

    FORMAT_STRS = {'day':       '%m/%d/%y',
                   'month':     '%b',
                   'year':      '%Y',
                   'hour':      '%H:%M',
                   'halfhour':  '%H:%M'
                   }
    names = date_range.strftime(FORMAT_STRS[summarize_by]).to_series()#.unique().to_series()
    names.index = np.arange(len(names))

    return names


def query_all_vehicles(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, sort_order=None, other_criteria='', drop_null=False):

    ########## Query non-training buses
    buses, training_buses = query_buses(output_fields, field_names, start_date, end_date, date_range, summarize_by, engine, is_subquery=True, other_criteria=other_criteria)
    buses.add(training_buses, fill_value=0)

    # Query GOVs
    simple_output_fields = get_output_field_names(date_range, summarize_by)
    where_clause = "datetime BETWEEN '{start_date}' AND '{end_date}' " \
                   "AND destination NOT LIKE 'Primrose%%' "\
        .format(start_date=start_date, end_date=end_date) \
        + other_criteria

    govs = query.simple_query_by_datetime(engine, 'nps_vehicles', field_names=field_names['nps_vehicles'], other_criteria=where_clause, summarize_by=summarize_by, output_fields=simple_output_fields)
    govs.index = ['GOV']


    # POVs
    povs = pd.DataFrame(np.zeros((1, output_fields.shape[0]), dtype=int),
                        columns=output_fields,
                        index=['POV'])
    for table_name in POV_TABLES:
        df = query.simple_query_by_datetime(engine, table_name, field_names=field_names[table_name],
                                other_criteria=where_clause, summarize_by=summarize_by,
                                output_fields=simple_output_fields)
        df.index = ['POV']
        povs = povs.add(df, fill_value=0)
    povs.drop(povs.columns[(povs == 0).all(axis=0)], axis=1, inplace=True)

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
              'summarize_by': summarize_by,
              'filter_fields': True
              }

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

    bus_output_fields = get_output_field_names(date_range, summarize_by)
    kwargs['output_fields'] = bus_output_fields#'vehicle_type text, ' + (' int, '.join(bus_output_fields)) + ' int'

    buses = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type', **kwargs)

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
    training_buses = query.crosstab_query_by_datetime(engine, 'buses', start_date, end_date, 'bus_type', **kwargs)

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

    output_fields = get_output_field_names(date_range, summarize_by)
    data = query.crosstab_query_by_datetime(engine, 'nps_vehicles', start_date, end_date, 'work_group', field_names=field_names['nps_vehicles'], other_criteria=other_criteria, summarize_by=summarize_by, output_fields=output_fields, filter_fields=True)

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

    sql_statements = [
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

    date_range = get_date_range(start_date, end_date, summarize_by=summarize_by)
    output_fields = get_output_field_names(date_range, summarize_by)
    all_data = []
    for table_name, print_name, criteria in sql_statements:
        data = query.simple_query_by_datetime(engine, table_name, field_names=field_names[table_name],
                                  summarize_by=summarize_by, output_fields=output_fields,
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

    return data, cols[drop_inds]


def show_legend(legend_title, label_suffix=None):
    ax = plt.gca()
    handles, labels = ax.get_legend_handles_labels()
    if label_suffix:
        labels = [l + label_suffix[l] for l in labels]
    legend = plt.legend(handles[::-1], labels[::-1], bbox_to_anchor=(1.04, 0),
                        loc='lower left', title=legend_title, frameon=False)
    legend._legend_box.align = 'left'
    max_label_length = max(map(len, labels))
    proportional_adjustment = (0.1 * max_label_length / 30.0)  # type: float
    right_adjustment = 0.75 - proportional_adjustment
    plt.subplots_adjust(right=right_adjustment, bottom=.15)  # make room for legend and x labels


def plot_bar(all_data, x_labels, out_png, bar_type='stacked', vehicle_limits=None, title=None, legend_title='', max_xticks=20, colors={}, plot_totals=False, show_percents=False, remove_gaps=False):

    if plot_totals:
        all_data.loc['Total'] = all_data.sum(axis=0)

    n_vehicles, n_dates = all_data.shape
    if remove_gaps:
        spacing_factor = int(n_vehicles) if bar_type == 'grouped' else 1
    else:
        spacing_factor = int(n_vehicles * 1.3) if bar_type == 'grouped' else 2
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
                    zorder=0)

    last_top = np.zeros(n_dates)
    for i, (vehicle_type, data) in enumerate(all_data.iterrows()):
        # If a color for this vehicle type isn't given, set a random color
        color = colors[vehicle_type] if vehicle_type in colors else np.random.rand(3)

        # If the bars are grouped, make sure they're offset. If they're stacked or just regular bars, just pass
        #   x indices that are evenly spaced
        if bar_type == 'stacked':
            x_inds = date_index
        elif bar_type == 'grouped':
            x_inds = date_index - bar_width * grouped_index[i]
        else: # bar_type == 'bar'
            x_inds = [bar_index[i]]

        ax.bar(x_inds, data, bar_width, bottom=last_top, label=vehicle_type, zorder=i + 1, color=color)

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

        last_top += data if bar_type == 'stacked' else 0

    x_tick_inds = bar_index if bar_type == 'bar' else date_index

    if len(x_labels) > 1:
        x_tick_interval = 1 if bar_type == 'bar' else max(1, int(round(n_dates/float(max_xticks))))
        if bar_type == 'bar':
            x_labels = pd.Series(all_data.index, x_labels.index) # The vehicle types
        plt.xticks(x_tick_inds[::x_tick_interval], x_labels[::x_tick_interval], rotation=45, rotation_mode='anchor', ha='right')
    else:
        plt.xticks([], []) # Don'

    # If adding horizonal lines, make sure their values are noted on the y axis. Otherwise, just
    #   use the default ticks
    if vehicle_limits:
        plt.yticks(np.unique((list(ax.get_yticks()) + vehicle_limits)))

    # Set enough space on either end of the plot
    if bar_type == 'grouped':
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

    plt.savefig(out_png.replace('.png', '_%s.png' % bar_type), dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop


def plot_line(all_data, x_labels, out_png, vehicle_limits=None, title=None, legend_title=None, max_xticks=20, colors={}, plot_type='line', show_stats=False, plot_totals=False):

    if plot_totals:
        all_data.loc['Total'] = all_data.sum(axis=0)

    n_vehicles, n_dates = all_data.shape
    stats_labels = {}
    data_stats = []

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
    sns.despine()

    # Grouped bar charts are too small to read at the default width so widen if bars are grouped
    figure = plt.gcf()
    width = figure.get_figwidth()
    # Make sure the width scale is between 1 and 3
    width_scale = max(1, min(n_dates/float(max_xticks), 3))
    figure.set_figwidth(width * width_scale)

    this_png = out_png.replace('.png', '_%s.png' % plot_type.replace(' ', '_'))
    plt.savefig(this_png, dpi=300)
    figure.set_figwidth(width) # reset because clf() doesn't set this back to the default
    plt.clf() # clear the figure in case the function was called within a loop

    if data_stats:
        data_stats = pd.DataFrame(data_stats, index=all_data.index)
        data_stats.to_csv(this_png.replace('.png', '_stats.csv'))


def write_metadata(out_dir, queries, summarize_by, start_date, end_date, plot_vehicle_limits, strip_data, use_gmp_dates, show_stats, plot_totals):

    QUERY_DESCRIPTIONS = {'summary':    'all vehicles aggregated in broad categories',
                          'buses':      'buses by each type found in the "bus_type" column of the "buses" table',
                          'nps':        'NPS vehicles by work group',
                          'pov':        'all private vehicles by type',
                          'total':      'total of all vehicles'}

    command = subprocess.list2cmdline(sys.argv)

    descr = "This folder contains queried data and derived plots from the Savage Box database. Data were summarize by {summarize_by} for dates between {start} and {end}. "\
        .format(summarize_by=summarize_by, start=start_date, end=end_date)
    descr += "Queries run include:\n\t-" + "\n\t-".join([q + ": " + QUERY_DESCRIPTIONS[q] for q in queries])


    options_desc = "\n\nAdditional options specified:\n\t-"
    options = []
    if plot_vehicle_limits:
        options.append("queries were limited to only observations that occurred between May 20 and Sep 15")
    if strip_data:
        options.append("the first and last sets of consecutive null dates/times were removed")
    if use_gmp_dates:
        options.append("in addition to %s-%s, any records outside the GMP allocation period (5/20-9/15) "
                       "were excluded from the query" % (start_date, end_date))
    if show_stats:
        options.append("relevant stats for the plot type were displayed in the legend")
    if plot_totals:
        options.append("totals were plotted for all vehicle types")
    if options:
        options_desc += "\n\t-".join(options)
        descr += options_desc

    msg = descr + \
          "\n\nFor questions, please contact Sam Hooper at samuel_hooper@nps.gov\n" \
          "\nSCRIPT: {script}" \
          "\nTIME PROCESSED: {datestamp}" \
          "\nCOMMAND: {command}"\
              .format(script=__file__,
                      datestamp=datetime.now().strftime('%Y/%m/%d %H:%M:%S'),
                      command=command)

    readme_path = os.path.join(out_dir, '_0README.txt')
    with open(readme_path, 'w') as readme:
        readme.write(msg)


def main(connection_txt, start_date, end_date, out_dir=None, out_csv=None, plot_types='stacked bar', summarize_by='day', queries=None, strip_data=False, plot_vehicle_limits=False, use_gmp_dates=False, show_stats=False, plot_totals=False, show_percents=False, max_queried_columns=1599, drop_null=False, remove_gaps=False):

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

    sys.stdout.write("Log file for count_vehicles_by_type.py: %s\n" % datetime.now().strftime('%H:%M:%S %m/%d/%Y'))
    sys.stdout.flush()

    # If nothing is passed, assume that all queries should be run
    if not queries:
        queries = ['summary']#'nps', 'buses', 'other']
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
        valid_strings = [s in ['stacked bar', 'grouped bar', 'line', 'best fit', ''] for s in plot_types]
        if not any(valid_strings):
            warnings.warn('No valid plot type string found in plot_types: %s. No plots will be made.'
                          % ', '.join(plot_types))

    if plot_vehicle_limits and summarize_by != 'day' and summarize_by != 'doy':
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

    start_date = start_datetime.strftime(DATETIME_FORMAT)
    end_date = end_datetime.strftime(DATETIME_FORMAT)

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
    #if summarize_by == 'day':
    #    summarize_by = 'doy'

    # Create output field names as a string
    date_range = get_date_range(start_date, end_date, summarize_by=summarize_by)
    output_fields = get_output_field_names(date_range, summarize_by)

    x_labels = get_x_labels(date_range, summarize_by)
    x_labels.index = output_fields

    for query_name in queries:
        if query_name not in QUERY_FUNCTIONS:
            warnings.warn('Invalid query name found: "%s". Query names must be separated'
                          ' by a comma and be one of the following: %s' %
                          (query_name, ', '.join(QUERY_FUNCTIONS.keys())),
                          RuntimeWarning)
            queries.remove(q)
            continue

        query_function = QUERY_FUNCTIONS[query_name]

        # Process the query in chunks because PostgreSQL has a limit of 1600 columns in a query result,
        #   which a user-defined query could exceed
        n_dates = len(output_fields)
        chunk_inds = np.arange(0, n_dates, max_queried_columns) + max_queried_columns
        start_index = 0
        all_data = []
        for index in chunk_inds:
            index = min(index, n_dates)
            these_output_fields = output_fields.iloc[start_index : index]
            this_date_range = date_range[start_index : index]

            data = query_function(these_output_fields, field_names, output_fields.index[start_index], output_fields.index[index - 1], this_date_range, summarize_by, engine, sort_order=SORT_ORDER[query_name], other_criteria=gmp_date_criteria)
            if 'total' in data.columns:
                data.drop('total', axis=1, inplace=True) # drop it here because we'll need to recreate it after concatenation
            all_data.append(data)
            start_index = index
        data = pd.concat(all_data, axis=1)

        # Remove rows without any data
        data.fillna(0, inplace=True)
        data = data.loc[data.sum(axis=1) > 0]

        these_labels = x_labels.copy()

        # If drop_null isn't true, make sure all dates are included, even if they don't have any data
        if not drop_null:
            data = data.reindex(columns=output_fields).fillna(0)
        # Otherwise, if stip_data is true, remove empty columns from edges of the data
        elif strip_data:
            data, drop_inds = strip_dataframe(data)
            these_labels = these_labels.drop(drop_inds) #drop the same labels

        #if not plot_totals:
        #data.drop('total', axis=1, inplace=True)
        data = data.reindex(columns=data.columns.sort_values())  # make sure they're in chronological order

        # If only 1 interval was found or given, drop the last label because it's extraneous
        if len(data.columns) == 1:
            these_labels = these_labels.iloc[[0]]

        if len(data.columns) != len(these_labels):
            warnings.warn("Some dates/times between {start} and {end} did not contain any data".format(start=start_date, end=end_date))

        # Make sure labels match up with the output columns
        these_labels = these_labels.reindex(data.columns)

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

        # PLot stuff
        vehicle_limits = []
        if plot_vehicle_limits:
            if query_name == 'summary':
                if summarize_by == 'doy':
                    vehicle_limits = [91, 160]
                elif summarize_by == 'year':
                    vehicle_limits = [10512]
            elif query_name == 'buses' and summarize_by == 'doy':
                vehicle_limits = [91]
            elif query_name == 'total':
                if summarize_by == 'doy':
                    vehicle_limits = [160]
                elif summarize_by == 'year':
                    vehicle_limits = [10512]
            else:
                vehicle_limits = [] # doesn't make sense for other plots

        out_png = this_csv_path.replace('.csv', '.png')
        colors = COLORS[query_name]
        title = '{prefix} past Savage by {interval}, {start}-{end}'\
            .format(prefix=TITLE_PREFIXES[query_name], interval=summarize_by,
                    start=these_labels.iloc[0], end=these_labels.iloc[-1])
        if 'bar' in plot_types:
            plot_bar(data, these_labels, out_png, bar_type='bar', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'stacked bar' in plot_types:
            plot_bar(data, these_labels, out_png, bar_type='stacked', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'grouped bar' in plot_types:
            plot_bar(data, these_labels, out_png, bar_type='grouped', vehicle_limits=vehicle_limits, title=title, colors=colors, show_percents=show_percents, remove_gaps=remove_gaps)
        if 'line' in plot_types:
            plot_line(data, these_labels, out_png, vehicle_limits=vehicle_limits, title=title, colors=colors, plot_totals=plot_totals)
        if 'best fit' in plot_types:
            plot_line(data, these_labels, out_png, vehicle_limits=vehicle_limits, title=title, colors=colors,
                      plot_type='best fit', show_stats=show_stats, plot_totals=plot_totals)

        '''else:
            raise ValueError('plot_type "%s" not understood. Must be either "stacked bar", "grouped bar", or "line"')'''
    write_metadata(out_dir, queries, summarize_by, start_date, end_date, plot_vehicle_limits, strip_data, use_gmp_dates, show_stats, plot_totals)

    print '\nOutput files written to', out_dir


if __name__ == '__main__':

    # Any args that don't have a default value and weren't specified will be None
    cl_args = {k: v for k, v in docopt.docopt(__doc__).iteritems() if v is not None}

    # get rid of extra characters from doc string and 'help' entry
    args = {re.sub('[<>-]*', '', k): v for k, v in cl_args.iteritems()
            if k != '--help' and k != '-h'}

    sys.exit(main(**args))
