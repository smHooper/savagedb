import os, sys
import subprocess
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns


import query
import count_vehicles_by_type as count

SUMMARIZE_BY = 'day'
GMP_LIMIT = 10512

# turn off the stupid setting as copy warning, which getting the day of the season will set off
pd.options.mode.chained_assignment = None

def get_normalized_daily_mean(query_year, connection_txt):
    ''' Return a dataframe of daily totals for query year and a series of mean daily totals for the last 5 years normalized to 10,512 (sum of daily totals == 10512)'''

    # We want to compare to the last 5 years of data so go 6 years back. The first 5 are for comparison and the most
    #  recent is the year of interest
    start_datetime = datetime(query_year - 6, 5, 15)
    # Just get all the data at first, then filter out this year's data. That way we only have to query the DB once
    end_datetime = datetime(query_year, 9, 30)

    # Get start and end dates for each season
    gmp_starts, gmp_ends = count.get_gmp_dates(start_datetime, end_datetime)
    btw_stmts = []
    for gmp_start, gmp_end in zip(gmp_starts, gmp_ends):
        btw_stmts.append("(datetime::date BETWEEN '{start}' AND '{end}') "
                         .format(start=gmp_start.strftime('%Y-%m-%d'),
                                 end=gmp_end.strftime('%Y-%m-%d'))
                         )
    gmp_date_criteria = ' AND (%s) ' % ('OR '.join(btw_stmts))
    start_datetime = max(start_datetime, gmp_starts.min().to_pydatetime())
    end_datetime = min(end_datetime, gmp_ends.max().to_pydatetime())
    start_date = start_datetime.strftime(count.DATETIME_FORMAT)
    end_date = end_datetime.strftime(count.DATETIME_FORMAT)

    # Get date range and names of output fields (formatted dates)
    date_range = count.get_date_range(start_date, end_date, summarize_by=SUMMARIZE_BY)
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
    normalized_mean = previous_data.groupby('day_of_season').normalized_total.mean()

    return current_data, normalized_mean


def main(connection_txt, query_year, out_path, mean_accuracy_txt=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    BAR_SPACING = 3

    sns.set_style('white')
    sns.set_context('paper')

    query_year = int(query_year)
    current_data, normalized_mean = get_normalized_daily_mean(query_year, connection_txt)

    # Calculate projected total and get projected daily values for plotting
    pct_difference = ((current_data.daily_total - normalized_mean) / normalized_mean).dropna()
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

    projected_remaining = (normalized_mean[remaining_days] * mean_pct_diff) + normalized_mean[remaining_days]
    projected_daily = pd.concat([current_data.daily_total, projected_remaining]).round(0).astype(int)

    # Plot the data. Projected values should be slightly grayed out (translucent)
    x_inds = pd.Series(projected_daily.index * BAR_SPACING, index=projected_daily.index)
    plt.bar(x_inds[current_data.index], projected_daily[current_data.index], 2, label='Actual daily total', color='k')
    plt.bar(x_inds[remaining_days], projected_daily[remaining_days], 2, label='Projected daily total', color='k', alpha=0.25)
    plt.hlines(normalized_mean[current_data.index], x_inds[current_data.index] - 1, x_inds[current_data.index] + 1,
               label='Typical daily total', color='firebrick', zorder=100)
    plt.hlines(normalized_mean[remaining_days], x_inds[remaining_days] - 1, x_inds[remaining_days] + 1,
               color='firebrick', alpha=0.5, zorder=101)

    # Get date labels for this year
    x_labels = count.get_x_labels(date_range, SUMMARIZE_BY)

    plt.xticks(x_inds[::10], x_labels[::10], rotation=45, rotation_mode='anchor', ha='right')

    plt.legend()

    error_str = ''
    if mean_accuracy_txt:
        try:
            mean_accuracy = pd.read_csv(mean_accuracy_txt, usecols=['mean_accuracy', 'day_of_season'], index_col='day_of_season').squeeze()
            day_of_season = current_data.index.max()
            error_margin = int(round(mean_accuracy[day_of_season] * projected_daily.sum()))
            error_str = r' $\pm$ %s' % error_margin
        except Exception as e:
            pass
    plt.title('Projected daily total vehicle counts per day for {year} as of {today}\nProjected season total - {total:,}{error}'
              .format(year=query_year,
                      today=x_labels[current_data.index.max()],
                      total=projected_daily.sum(),
                      error=error_str))
    plt.xlim(-BAR_SPACING, max(remaining_days) * BAR_SPACING + BAR_SPACING)
    sns.despine()

    # Widen the plot
    figure = plt.gcf()
    figure.set_figwidth(figure.get_figwidth() * 2.5)

    plt.savefig(out_path, dpi=300)

    print '\nOutput files written to', os.path.dirname(out_path)

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))




