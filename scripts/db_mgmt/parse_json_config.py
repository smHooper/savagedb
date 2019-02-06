import os, sys
import json
import warnings
import subprocess
from datetime import datetime
import pandas as pd



def main(json_path, out_dir=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.flush()

    try:
        with open(json_path) as json_file:
            json_data = json.load(json_file)['fields']
    except:
        raise IOError("Problem reading json file: %s" % json_path)


    field_options = []
    field_config = pd.DataFrame(columns=['context', 'field_name', 'database_table', 'database_field',
                                         'sorted'])
    # Create one csv of data with one col per option, and one with metadata
    for context, field_info in json_data.iteritems():
        for field_name, field in field_info.iteritems():
            # Add a 1-column df for each set of options to the field_options list
            field_options.append(pd.DataFrame({field_name: field['options']}))

            # Add info to config df
            field['context'] = context
            field['field_name'] = field_name
            field_config = field_config.append(pd.Series(field), ignore_index=True)

    # Join all field options like an outer join
    field_options = pd.concat(field_options, axis=1)

    # Remove the "options" column, which came with each 'field' that was appended
    field_config.drop('options', axis=1, inplace=True)


    if not out_dir:
        out_dir = os.path.join(os.path.dirname(json_path), '_temp')
        os.mkdir(out_dir)
    else:
        try:
            if os.path.isdir(out_dir):
                out_dir = os.path.join(out_dir, '_temp')
                os.mkdir(out_dir)
            else:
                out_dir = os.path.join(out_dir, '_temp')
                os.makedirs(out_dir)
        except Exception as e:
            warnings.warn('could not create out_dir because %s. Using dir of json_path' % e.message)
            out_dir = os.path.join(os.path.dirname(json_path), '_temp')
            os.mkdir(out_dir)
    subprocess.call(["attrib", "+H", out_dir])

    field_options.to_csv(os.path.join(out_dir, 'json_config_dropdown_options.csv'), index=False)
    field_config.to_csv(os.path.join(out_dir, 'json_config_field_options.csv'), index=False)

    print 'Parsed data written to %s' % out_dir

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
