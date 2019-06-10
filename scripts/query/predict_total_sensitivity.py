import os, sys
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import seaborn as sns

from predict_season_vehicle_total import get_normalized_daily_mean, GMP_LIMIT

pd.options.mode.chained_assignment = None

def main(connection_txt, out_path, start_year=None, end_year=None):

    sns.set_style('darkgrid')

    current_year = datetime.now().year

    # Calculate an accuracy curve for the last 5 years
    accuracy_curves = {}
    all_predictions = {}
    print '\nChecking sensitivity for ',
    for year in range(current_year - 5 if not start_year else int(start_year), current_year if not end_year else int(end_year) + 1):
        #if year < 2016: continue
        print '%s...' % year,
        current_data, normalized_mean = get_normalized_daily_mean(year, connection_txt)
        this_sum = float(current_data.daily_total.sum())

        # Calculate projected value for each day in this year's data (should always be a full season
        accuracies = {}
        predictions = {}
        for day in current_data.index:
            this_data = current_data[:day + 1]
            pct_difference = ((this_data.daily_total - normalized_mean) / normalized_mean).dropna()
            mean_pct_diff = pct_difference.mean()

            # The projected daily total series should be all of the days in the season up to this point combined
            #   with the remaining days of projected values
            remaining_days = normalized_mean.index[~normalized_mean.index.isin(this_data.index) &
                                                   (normalized_mean.index <= current_data.index.max())]
            projected_remaining = (normalized_mean[remaining_days] * mean_pct_diff) + normalized_mean[remaining_days]
            projected_daily = pd.concat([this_data.daily_total, projected_remaining]).round(0).astype(int)
            #projected_total = GMP_LIMIT + mean_pct_diff * GMP_LIMIT
            accuracies[day] = (projected_daily.sum() - this_sum)/this_sum * 100
            predictions[day] = projected_daily.sum()

        accuracy_data = pd.Series(accuracies)
        accuracy_curves[year] = accuracy_data
        all_predictions[year] = pd.Series(predictions)
        plt.plot(current_data.index, accuracy_data, label=year)

    sns.despine()

    plt.title('Accuracy of projected season total per day of the season')
    plt.legend()
    plt.xlabel('Day of season')
    plt.ylabel('% difference from actual total')

    # Widen the plot
    figure = plt.gcf()
    figure.set_figwidth(figure.get_figwidth() * 2.5)

    accuracy_txt = out_path.replace(out_path.split('.')[-1], 'csv')
    accuracy_curves = pd.DataFrame(accuracy_curves)
    accuracy_curves.index.name = 'day_of_season'
    accuracy_curves['mean_accuracy'] = accuracy_curves.apply(lambda x: x.abs().mean() * .01, axis=1)
    accuracy_curves.to_csv(accuracy_txt)
    pd.DataFrame(all_predictions, index=accuracy_curves.index).to_csv(accuracy_txt.replace('.csv', '_predicted_totals.csv'))

    print '\n\nPlot image written to %s' % out_path
    plt.savefig(out_path, dpi=300)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))