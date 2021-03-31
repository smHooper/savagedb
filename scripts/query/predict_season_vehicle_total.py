import os, sys
import subprocess
import pandas as pd
import numpy as np
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib import collections
from matplotlib.legend_handler import HandlerLineCollection
import seaborn as sns


import query
import count_vehicles_by_type as count

SUMMARIZE_BY = 'day'
GMP_LIMIT = 10512
EXCLUDE_ESTIMATION_YEARS = pd.Series([2020]) #anomalous years to exclude from estimations

# turn off the stupid setting as copy warning, which getting the day of the season will set off
pd.options.mode.chained_assignment = None

def get_normalized_daily_mean(query_end_datetime, connection_txt):
    ''' Return a dataframe of daily totals for query year and a series of mean daily totals for the last 5 years normalized to 10,512 (sum of daily totals == 10512)'''

    # We want to compare to the last 5 years of data so go 6 years back. The first 5 are for comparison and the most
    #  recent is the year of interest
    query_year = query_end_datetime.year
    exclude_years = EXCLUDE_ESTIMATION_YEARS[
        (EXCLUDE_ESTIMATION_YEARS >= (query_year - 6)) &
        (EXCLUDE_ESTIMATION_YEARS < query_year)
    ]

    # Make sure at least 5 years of old data are used
    start_datetime = datetime(query_year - (6 + len(exclude_years)), 5, 15)

    # Just get all the data at first, then filter out this year's data. That way we only have to query the DB once
    end_datetime = datetime(query_year, 9, 30)
    # If querying for a particular day in the season, make end_datetime the earlier of either the given date or Sep 30
    if query_end_datetime < end_datetime:
        end_datetime = query_end_datetime

    # Get start and end dates for each season
    gmp_starts, gmp_ends = count.get_gmp_dates(start_datetime, end_datetime)
    btw_stmts = []
    for gmp_start, gmp_end in zip(gmp_starts, gmp_ends):
        # Skip any years in the EXCLUDE series
        gmp_year = gmp_start.year
        if gmp_year in exclude_years.values and gmp_year != query_year:
            continue
        this_end_date = gmp_end if gmp_end < end_datetime else end_datetime
        btw_stmts.append("(datetime::date BETWEEN '{start}' AND '{end}') "
                         .format(start=gmp_start.strftime('%Y-%m-%d'),
                                 end=this_end_date.strftime('%Y-%m-%d'))
                         )
    gmp_date_criteria = ' AND (%s) ' % ('OR '.join(btw_stmts))
    start_datetime = max(start_datetime, gmp_starts.min().to_pydatetime())
    end_datetime = min(end_datetime, gmp_ends.max().to_pydatetime())
    start_date = start_datetime.strftime(count.DATETIME_FORMAT)
    end_date = end_datetime.strftime(count.DATETIME_FORMAT)

    # Get date range and names of output fields (formatted dates)
    date_range = count.get_date_range(start_date, end_date, summarize_by=SUMMARIZE_BY)
    date_range = date_range[~date_range.year.isin(exclude_years)]
    output_fields = count.get_output_field_names(date_range, SUMMARIZE_BY, gmp_dates=[gmp_starts, gmp_ends])

    engine = query.connect_db(connection_txt)

    x_labels = count.get_x_labels(pd.to_datetime(output_fields.index), SUMMARIZE_BY)
    x_labels.index = output_fields
    field_names = query.query_field_names(engine)

    # Query database to get a count of all GMP vehicles by day
    data, _ = count.query_total(output_fields, field_names, output_fields.index[0], end_date, date_range, SUMMARIZE_BY, engine, other_criteria=gmp_date_criteria, use_gmp_vehicles=True)

    # data is returned as a 1-row df where each column is a different day, so make it a series
    data = data.squeeze()

    # Make it a dataframe again with a column for date
    data = pd.DataFrame({'datetime': pd.to_datetime(data.index, format=count.FORMAT_STRS[SUMMARIZE_BY]), 'daily_total': data})

    # For each year, record the day of the season. This will be used to align the days of different years. The reason
    #   for using day of season instead of day of year is because there is a weekly pattern to vehicle counts and the
    #   start day of the GMP regulatory period is always a Saturday. Using the day of the season will always align days
    #   by day of the week
    dfs = []
    for year, df in data.groupby(data.datetime.dt.year):
        df = df.sort_index()
        min_datetime = df.datetime.min()
        df['day_of_season'] = (df.datetime - min_datetime).dt.days
        df['year'] = year

        # Split the data into the first 5 years and last year. Calculate the daily total normalized by
        #   the 10512/(total for this year). This will make each year add up to 10512, so that when we take the average
        #   by day of season, we get some typical pattern of daily values if every year met the 10512 value exactly
        if year < query_year:
            df['normalized_total'] = df.daily_total * GMP_LIMIT/df.daily_total.sum()
            dfs.append(df)
        else:
            current_data = df.set_index('day_of_season')

    previous_data = pd.concat(dfs)
    grouped = previous_data.groupby('day_of_season').normalized_total
    normalized_data = pd.DataFrame({'nmean': grouped.mean(), 'nmax': grouped.max(), 'nmin': grouped.min()})

    return current_data, normalized_data


class VerticalDashedLineHandler(object):
    def legend_artist(self, legend, orig_handle, fontsize, handlebox):
        x0, y0 = handlebox.xdescent, handlebox.ydescent
        width, height = handlebox.width, handlebox.height
        new_x = x0 + width/2
        line = plt.Line2D([new_x, new_x], [y0 - height/4, height * 1.5], linestyle=(0, (1.5, 1.5)), color='k')
        handlebox.add_artist(line)

        return line


def main(connection_txt, out_img_path, mean_accuracy_txt=None, query_end_date=None, plot_type='bar'):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    BAR_SPACING = 1

    sns.set_style('white')
    sns.set_context('paper')

    if query_end_date:
        try:
            query_end_datetime = datetime.strptime(query_end_date, '%Y-%m-%d')
        except:
            raise ValueError(
                'Could not understand query_end_date %s. It must be in the format YYYY-MM-DD.' % query_end_date
            )
    else:
        query_end_datetime = datetime.now()
    query_year = query_end_datetime.year

    current_data, normalized_mean = get_normalized_daily_mean(query_end_datetime, connection_txt)

    # Calculate projected total and get projected daily values for plotting
    pct_difference = ((current_data.daily_total - normalized_mean.nmean) / normalized_mean.nmean).dropna()
    mean_pct_diff = pct_difference.mean()
    #projected_total = int(round(GMP_LIMIT + mean_pct_diff * GMP_LIMIT))

    # The projected daily total series should be all of the days in the season up to this point combined
    #   with the remaining days of projected values. Only use the projected values that are before the last day of data
    #   for this year beign evaluated since there could be a year in two in the previous 5 years where the season was
    #   longer than the current one
    start_date, end_date = count.get_gmp_dates(datetime(query_year, 1, 1), datetime(query_year, 9, 30))

    date_range = count.get_date_range(start_date.strftime(count.DATETIME_FORMAT)[0],
                                      end_date.strftime(count.DATETIME_FORMAT)[0],
                                      summarize_by=SUMMARIZE_BY)

    remaining_days = normalized_mean.index[normalized_mean.index.isin(range(len(date_range))) &
                                           (normalized_mean.index > current_data.index.max())]

    projected_remaining = (normalized_mean.loc[remaining_days, 'nmean'] * mean_pct_diff) + normalized_mean.loc[remaining_days, 'nmean']
    projected_daily = pd.concat([current_data.daily_total, projected_remaining]).round(0).astype(int)

    # Plot the data. Projected values should be slightly grayed out (translucent)
    x_inds = pd.Series(projected_daily.index * BAR_SPACING, index=projected_daily.index)
    if plot_type == 'bar':
        plt.bar(x_inds[current_data.index], projected_daily[current_data.index], 1, label='Actual daily total', color='k', ec='white', lw=0.5)
        plt.bar(x_inds[remaining_days], projected_daily[remaining_days], 1, label='Projected daily total', color='k', ec='white', lw=0.5, alpha=0.3)
        plt.hlines(normalized_mean.loc[current_data.index, 'nmean'], x_inds[current_data.index] - 0.45, x_inds[current_data.index] + 0.45, label='Typical daily total', color='firebrick', zorder=100)
        plt.hlines(normalized_mean.loc[remaining_days, 'nmean'], x_inds[remaining_days] - 0.45, x_inds[remaining_days] + 0.45, color='firebrick', alpha=0.3, zorder=101)
        plt.legend(frameon=False)#'''
    else:
        plt.vlines(x_inds[current_data.index], normalized_mean.loc[current_data.index, 'nmin'], normalized_mean.loc[current_data.index, 'nmax'],
                   label='Typical daily range', linestyle=(0, (1.5, 2)))
        plt.vlines(x_inds[remaining_days], normalized_mean.loc[remaining_days, 'nmin'], normalized_mean.loc[remaining_days, 'nmax'],
                   colors='0.7', linestyle=(0, (1.5, 2)))
        plt.scatter(x_inds[current_data.index], projected_daily[current_data.index], s=10, color='k', label='Actual daily total')
        plt.scatter(x_inds[remaining_days], projected_daily[remaining_days], s=10, color='0.7', label='Projected daily total')
        plt.legend(frameon=False, handler_map={collections.LineCollection: VerticalDashedLineHandler()})

    # Get date labels for this year
    x_labels = count.get_x_labels(date_range, SUMMARIZE_BY)

    plt.xticks(x_inds[::10], x_labels[::10], rotation=45, rotation_mode='anchor', ha='right')

    error_str = ''
    if mean_accuracy_txt:
        try:
            mean_accuracy = pd.read_csv(mean_accuracy_txt, usecols=['mean_accuracy', 'day_of_season'], index_col='day_of_season').squeeze()
            day_of_season = current_data.index.max()
            error_margin = int(round(mean_accuracy[day_of_season] * projected_daily.sum()))
            error_str = r' $\pm$ %s' % error_margin
        except Exception as e:
            pass
    most_recent_data = x_labels[current_data.index.max()]
    plt.title('Projected daily total vehicle counts per day for {year} as of {today}\nProjected season total - {total:,}{error}'
              .format(year=query_year,
                      today=most_recent_data,
                      total=projected_daily.sum(),
                      error=error_str))
    plt.xlim(-BAR_SPACING, max(remaining_days) * BAR_SPACING + BAR_SPACING)
    #plt.ylim(0, max(normalized_mean.nmax.max(), projected_daily.max()) + 20)
    sns.despine()

    # Widen the plot
    figure = plt.gcf()
    figure.set_figwidth(figure.get_figwidth() * 2.5)

    plt.savefig(out_img_path, dpi=300)

    print '\nOutput files written to', os.path.dirname(out_img_path)

    return most_recent_data

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))




