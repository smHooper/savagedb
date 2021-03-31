import os
import sys
import shutil
from glob import glob
from datetime import datetime

import count_vehicles_by_type as count
import predict_season_vehicle_total as predict

CONNECTION_TXT = r'\\inpdenards\savage\config\connection_info.txt'
SENSITIVITY_PLOT_PATH = r'\\inpdenards\savage\config\predict_total_sensitivity_2002_2019.png'
IMG_OUTPUT_DIR = r'\\inpdenafiles\parkwide\databases\savage_check_station\total_season_vehicle_prediction' # change once a location is determined


def main():

    today = datetime.now().date()
    current_year = today.year
    gmp_start, gmp_end = zip(count.get_gmp_dates(datetime(current_year, 5, 1), datetime(current_year, 9, 30)))
    gmp_start = gmp_start[0].date[0]
    gmp_end = gmp_end[0].date[0]

    if today < gmp_start or today > gmp_end:
        sys.stdout.write('Current date is outside GMP dates. Exiting...')
        sys.stdout.flush()
        return

    mean_accuracy_txt = glob(
        os.path.join(
            os.path.dirname(__file__),
            '..',
            'predict_total_sensitivity*.csv')
    )
    if not len(mean_accuracy_txt):
        raise RuntimeError('No mean accuracy text file found')
    mean_accuracy_txt = mean_accuracy_txt[-1]

    if not os.path.isdir(IMG_OUTPUT_DIR):
        os.mkdir(IMG_OUTPUT_DIR)

    out_img_path = os.path.join(IMG_OUTPUT_DIR, 'predicted_season_vehicle_total.png')
    predict.main(CONNECTION_TXT, out_img_path, mean_accuracy_txt, today.strftime('%Y-%m-%d'))

    # Copy the sensitivity plot
    if os.path.isfile(SENSITIVITY_PLOT_PATH):
        try:
            shutil.copy(SENSITIVITY_PLOT_PATH, IMG_OUTPUT_DIR)
        except:
            raise

    # Copy the plot to the previous_graphs dir with a datestamp
    previous_plots_dir = os.path.join(IMG_OUTPUT_DIR, 'previous_graphs')
    if not os.path.exists(previous_plots_dir):
        os.mkdir(previous_plots_dir)
    try:
        shutil.copy(
            out_img_path,
            os.path.join(
                previous_plots_dir,
                os.path.basename(out_img_path).replace('.png', '_%s.png' % today.strftime('%Y_%b_%d'))
            )
        )
    except:
        raise


    readme_text = (
        'Description of {}:'
        '\n\n'
        'This graph was created with a script scheduled to run automatically once a day during the General Management'
        ' Plan (GMP) regulatory season (the Saturday before Memorial Day to the second Thursday of September or'
        ' September 15, whichever comes first). The script uses patterns found in the previous 5 years* of daily vehicle'
        ' totals to estimate the expected number of daily vehicles for remaining days of the season and total number of'
        ' vehicles for the season. Projections of daily vehicle totals for remaining days of the season are estimated'
        ' by calculating a normalized mean total for each day of the season in preceeding years and calculating the'
        ' percent difference from the current seasons daily totals. Since the start of each GMP regulatory season is'
        ' on a different day of the year each year, daily patterns are compared by relative day of the season as'
        ' opposed to the actual date.'
        '\n\n'
        'The accuracy of estimations generally increases as the season progresses. The file {} is a graph demonstrating'
        ' this pattern. As demonstrated in this additional graph, total estimations for the season are typically within'
        ' 5% of the eventual actual total by approximately 30 days into the season. Estimations before the 20th day of'
        ' the season are generally within 10% of the eventual total. The reliability of the estimate should be'
        ' considered accordingly.'
        '\n\n'
        '*2020 is excluded from estimation calculations since vehicle patterns departed significantly from normal.'
    ).format(os.path.basename(out_img_path), os.path.basename(SENSITIVITY_PLOT_PATH))

    readme_path = os.path.join(IMG_OUTPUT_DIR, 'README.txt')
    with open(readme_path, 'w') as f:
        f.write(readme_text)


if __name__ == '__main__':
    sys.exit(main())