import os, sys
from glob import glob
from datetime import datetime

import count_vehicles_by_type as count
import predict_season_vehicle_total as predict

CONNECTION_TXT = r'\\inpdenards\savage\config\connection_info.txt'
IMG_OUTPUT_DIR = os.path.dirname(__file__) # change once a location is determined


def main():

    today = datetime.now().date()
    current_year = today.year
    gmp_start, gmp_end = zip(count.get_gmp_dates(datetime(current_year, 5, 1), datetime(current_year, 9, 30)))
    gmp_start = gmp_start[0].date[0]
    gmp_end = gmp_end[0].date[0]

    if today < gmp_start or today > gmp_end:
        print('Current date is outside GMP dates. Exiting...')
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

    out_img_path = os.path.join(IMG_OUTPUT_DIR, 'predicted_season_vehicle_total_%s.png' % today.strftime('%Y_%b_%d'))
    predict.main(CONNECTION_TXT, out_img_path, mean_accuracy_txt, today.strftime('%Y-%m-%d'))


if __name__ == '__main__':
    sys.exit(main())