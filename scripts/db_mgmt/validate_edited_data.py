'''
Utility to validate data after it's been edited by the user in the front end import form (but before it's imported)
'''

import sys, os
import glob
import shutil
import subprocess
import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime

import validate_app_data

def main(db_dir, connection_txt, filename_tag=''):

    sys.stdout.write("Log file for %s: %s\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    search_str = os.path.join(db_dir, '*%s.csv' % filename_tag)
    db_path = os.path.join(db_dir, 'checked.db')
    engine = create_engine('sqlite:///' + db_path)

    if os.path.exists(db_path):
        os.remove(db_path)

    with engine.connect() as conn, conn.begin():
        # Create a bogus shift info table so validate_app_data.main() doesn't freak out
        pd.DataFrame({'a': [0]}).to_sql('sessions', conn, index=False)

        for csv in glob.glob(search_str):
            table_name = os.path.splitext(os.path.basename(csv))[0].replace(filename_tag, '')
            data = pd.read_csv(csv)
            data['id'] = range(len(data))
            data['date'] = pd.to_datetime(data.datetime).dt.strftime('%m/%d/%y')
            data['time'] = pd.to_datetime(data.datetime).dt.strftime('%H:%M')
            data.to_sql(table_name, conn, index=False)

    # Delete all of the validated app data, including the 'missing_values' file
    for csv in glob.glob(os.path.join(db_dir, '*_flagged.csv')):
        os.remove(csv)

    validate_app_data.main(db_path, connection_txt, output_dir=db_dir)

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))