import os, sys
import json
import shutil
import subprocess
from datetime import datetime
import pandas as pd


# Structure of the dict to dump into JSON needs to be:
# {
#   fields: {
#       context 1: {
#           app_field_name 1: {
#               sorted: <Bool>,
#               validation_table: <string>,
#               validation_field: <string>,
#               options: [
#                   "option 1",
#                   "option 2"
#               ]
#           },
#           app_field_name 2: {
#               ...
#           }
#       },
#       context 2: {
#           ...
#       }
#   }
# }


def main(data_dir, out_dir):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    dropdown_options = pd.read_csv(os.path.join(data_dir, 'json_config_dropdown_options_edited.csv'))
    field_properties = pd.read_csv(os.path.join(data_dir, 'json_config_field_properties_edited.csv'))\
        .set_index('attribute')\
        .fillna('') # Make null values just empty strings

    # Loop through each unique context first, because there can be multiple fields within a single
    #   context
    fields = {}
    for context, field_props in field_properties.T.groupby('context'):

        # Loop through each field in this context
        context_dict = {}
        for app_field_label, field_info in field_props.iterrows():
            field_dict = field_info.to_dict()
            field_dict['sorted'] = True if field_dict['sorted'] == 'True' else False

            # Add the options as a list
            if field_dict['sorted']:
                field_dict['options'] = sorted(dropdown_options[app_field_label].dropna())
            else:
                field_dict['options'] = dropdown_options[app_field_label].dropna().tolist()

            # remove context from dict because it's not a property of the field
            del field_dict['context']

            context_dict[app_field_label] = field_dict

        fields[context] = context_dict

    # Nest the whole dict in its own dict because if I ever develop other configuration options,
    #   they would be at the top level, not at the same level as individual fields or contexts
    config = {'fields': fields}

    out_json = os.path.join(out_dir, 'savageCheckerConfig.json')
    with open(out_json, 'w') as json_file:
        json.dump(config, json_file, indent=4)

    # Clean up the text files and temporary dir created by loading JSON to Access
    try:
        shutil.rmtree(data_dir)
    except:
        pass

    print 'JSON configuration file written to %s' % out_json


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
