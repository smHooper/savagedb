import os, sys
import json
import warnings
import subprocess
from datetime import datetime
import pandas as pd


COLUMN_ORDER = ["Observer name",
                "Bus type", "Lodge",
                "Inholder name",
                "Approved category",
                "Work group",
                "Trip purpose",
                "Destination"]


def parse_json_data(json_path):

    try:
        with open(json_path) as json_file:
            json_data = json.load(json_file)#['fields']
    except:
        raise IOError("Problem reading json file: %s" % json_path)

    # Retrieve dropdown options
    field_options = []
    field_properties = []

    # Create one csv of data with one col per option, and one with field properties
    for context, field_info in json_data['fields'].iteritems():
        for field_name, field in field_info.iteritems():

            if field['sorted']:
                field['options'] = sorted(field['options'])

            # Add a 1-column df for each set of options to the field_options list
            field_options.append(pd.DataFrame({field_name: field['options']}))

            # Do the same for field properties
            field['context'] = context
            del field['options']
            field_properties.append(pd.DataFrame({field_name: field}))

    # Join all field options like an outer join
    field_options = pd.concat(field_options, axis=1, sort=False)
    field_properties = pd.concat(field_properties, axis=1, sort=False)
    field_properties.index.name = 'attribute'
    these_columns = [c for c in COLUMN_ORDER if c in field_options.columns]
    field_options = field_options.reindex(columns=these_columns)
    field_properties = field_properties.reindex(index=['sorted', 'context', 'validation_table', 'validation_field'],
                                                columns=these_columns)

    return field_options, field_properties, json_data


def main(json_path, out_dir=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    field_options, field_properties, json_data = parse_json_data(json_path)

    # Retrieve global properties. They're all at the top level (i.e., "name": "value"), not dicts
    global_properties = {k: v for k, v in json_data.iteritems() if type(v) == str or type(v) == unicode or type(v) == bool}
    global_properties = pd.DataFrame(global_properties, index=[0])

    # Create a blank table to store missing values if any exist (not checked until export JSON button
    #   clicked in Access)
    missing_values = pd.DataFrame(columns=['data_value', 'data_table', 'data_field', 'lookup_table','lookup_field'])

    # If no output directory was given, just create a temp dir in the same dir as the json file
    if not out_dir:
        out_dir = os.path.join(os.path.dirname(json_path), '_temp')
        if not os.path.exists(out_dir):
            os.mkdir(out_dir)
    # Otherwise, try to create a temp in out_dir
    else:
        try:
            if os.path.isdir(out_dir):
                out_dir = os.path.join(out_dir, '_temp')
                os.mkdir(out_dir)
            else:
                out_dir = os.path.join(out_dir, '_temp')
                os.makedirs(out_dir)
        # If that fails,
        except Exception as e:
            warnings.warn('could not create out_dir because %s. Using dir of json_path' % e.message)
            out_dir = os.path.join(os.path.dirname(json_path), '_temp')
            if not os.path.exists(out_dir):
                os.mkdir(out_dir)
    subprocess.call(["attrib", "+H", out_dir]) # Make sure it's hidden

    field_options.to_csv(os.path.join(out_dir, 'json_config_dropdown_options.csv'), index=False)
    field_properties.to_csv(os.path.join(out_dir, 'json_config_field_properties.csv'))
    missing_values.to_csv(os.path.join(out_dir, 'json_config_missing_values.csv'), index=False)
    if len(global_properties):
        global_properties.to_csv(os.path.join(out_dir, 'json_config_global_properties.csv'), index=False)

    print 'Parsed data written to %s' % out_dir

if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
