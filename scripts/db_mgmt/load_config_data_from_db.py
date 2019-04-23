import sys
import os
import shutil
import warnings
import subprocess
import pandas as pd
from glob import glob
from datetime import datetime
from sqlalchemy import create_engine

sys.path.append(os.path.join(os.path.join(os.path.dirname(__file__), '..'), 'query'))
from query import connect_db
from parse_json_config import COLUMN_ORDER, parse_json_data


FIELD_PROPERTIES = pd.DataFrame([['bus_codes', 'Bus type', 'name', 'Bus'],
                                 ['bus_codes', 'Lodge',  'name', 'Lodge Bus'],
                                 ['inholder_allotments',  'Permit holder', 'inholder_name', 'Inholder'],
                                 ['nps_approved_codes', 'Approved category', 'name', 'NPS Approved'],
                                 ['nps_work_groups', 'Work group', 'name', 'NPS Vehicle'],
                                 ['nps_trip_purposes', 'Trip purpose', 'name', 'NPS Vehicle'],
                                 ['destination_codes', 'Destination', 'name', 'global'],
                                 ['', 'Observer name', '', 'global']
                                 ],
                              columns=['validation_table', 'config_column', 'validation_field', 'context'])#'''


def main(connection_txt, out_dir, json_path=None):

    sys.stdout.write("Log file for %s\n%s\n\n" % (__file__, datetime.now().strftime('%H:%M:%S %m/%d/%Y')))
    sys.stdout.write('Command: python %s\n\n' % subprocess.list2cmdline(sys.argv))
    sys.stdout.flush()

    if json_path:
        json_dropdown_options, json_field_properties = parse_json_data(json_path)

    # Get lookup values from the DB
    dropdown_options = []
    postgres_engine = connect_db(connection_txt)
    for _, table_info in FIELD_PROPERTIES.iterrows():
        if table_info.validation_table:
            sql = "SELECT DISTINCT {validation_field} FROM {validation_table};".format(**table_info)
            if table_info.config_column == 'Bus type':
                sql = sql.replace(';', " WHERE NOT is_lodge_bus;")
            elif table_info.config_column == 'Lodge':
                sql = sql.replace(';', " WHERE is_lodge_bus;")
            elif table_info.config_column == 'Destination':
                sql = "SELECT name FROM (SELECT * FROM destination_codes ORDER BY mile) AS foo;"
            with postgres_engine.connect() as conn, conn.begin():
                db_values = pd.read_sql(sql, conn).squeeze()
            db_values = db_values[db_values != 'Null']

            # if a JSON config file was given, append new values from the DB to the existing values
            if json_path:
                json_values = json_dropdown_options[table_info.config_column].dropna()
                missing = json_values.loc[~json_values.isin(db_values)]
                db_values = missing.append(db_values)
                if json_field_properties.loc['sorted', table_info.config_column]:
                    db_values = db_values.sort_values()

            dropdown_options.append(pd.DataFrame({table_info.config_column: db_values.tolist()}))

        else:
            values = []
            if json_path:
                values += json_dropdown_options[table_info.config_column].tolist()
            dropdown_options.append(pd.DataFrame({table_info.config_column: values}))

    # Concatenate all of the options into a single dataframe
    field_options = pd.concat(dropdown_options, axis=1, sort=False).reindex(columns=COLUMN_ORDER)

    # If json_path was given, use the field_properties from the JSON config file
    if json_path:
        field_properties = json_field_properties.copy()
    # Otherwise, reformat the FIELD_PROPERTIES df
    else:
        field_properties = FIELD_PROPERTIES.set_index('config_column').T.reindex(columns=COLUMN_ORDER)
        field_properties.loc['sorted'] = False
        field_properties.index.name = 'attribute'

    # Create the missing values CSV because the VBA code will expect it even though there won't be any missing values
    missing_values = pd.DataFrame(columns=['data_value', 'data_table', 'data_field', 'lookup_table', 'lookup_field'])

    try:
        if os.path.isdir(out_dir):
            out_dir = os.path.join(out_dir, '_temp')
            if not os.path.isdir(out_dir):
                os.mkdir(out_dir)
        else:
            out_dir = os.path.join(out_dir, '_temp')
            os.makedirs(out_dir)
    except Exception as e:
        raise IOError('Could not create output directory at %s because %s' % (out_dir, e.message))
    subprocess.call(["attrib", "+H", out_dir]) # Make sure it's hidden

    field_options.to_csv(os.path.join(out_dir, 'json_config_dropdown_options.csv'), index=False)
    field_properties.to_csv(os.path.join(out_dir, 'json_config_field_properties.csv'))
    missing_values.to_csv(os.path.join(out_dir, 'json_config_missing_values.csv'), index=False)

    print 'Parsed data written to %s' % out_dir


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

