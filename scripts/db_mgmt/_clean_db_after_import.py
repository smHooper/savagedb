import sys, os
import warnings
import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine


INTEGER_FIELDS = {'accessibility':      ['n_passengers'],
                  'buses':              ['n_passengers', 'n_wheelchair', 'n_lodge_ovrnt'],
                  'cyclists':           ['n_passengers'],
                  'employee_vehicles':  ['n_passengers', 'permit_number'],
                  'inholders':          ['n_passengers', 'permit_number'],
                  'nps_approved':       ['n_nights', 'n_passengers'],
                  'nps_contractors':    ['n_nights', 'n_passengers'],
                  'nps_vehicles':       ['n_nights', 'n_passengers'],
                  'photographers':      ['n_nights', 'n_passengers'],
                  'road_lottery':       ['n_passengers', 'permit_number'],
                  'subsistence':        ['n_nights', 'n_passengers'],
                  'tek_campers':        ['n_passengers'],
                  'turned_around':      ['n_passengers']
                  }
VARCHAR_FIELDS = {'accessibility':      ['destination', 'driver_name', 'entered_by', 'entry_method'],
                  'buses':              ['destination', 'driver_name', 'entered_by', 'entry_method', 'bus_type'],
                  'cyclists':           ['destination', 'entered_by', 'entry_method'],
                  'employee_vehicles':  ['destination', 'driver_name', 'entered_by', 'entry_method'],
                  'inholders':          ['destination', 'driver_name', 'entered_by', 'entry_method', 'permit_holder'],
                  'nps_approved':       ['destination', 'driver_name', 'entered_by', 'entry_method', 'approved_type'],
                  'nps_contractors':    ['destination', 'organization', 'entered_by', 'entry_method', 'trip_purpose'],
                  'nps_vehicles':       ['destination', 'driver_name', 'entered_by', 'entry_method', 'trip_purpose', 'work_group'],
                  'other_vehicles':     ['destination', 'entered_by', 'entry_method'],
                  'photographers':      ['destination', 'driver_name', 'entered_by', 'entry_method', 'permit_holder'],
                  'road_lottery':       ['destination', 'entered_by', 'entry_method'],
                  'subsistence':        ['destination', 'driver_name', 'entered_by', 'entry_method'],
                  'tek_campers':        ['destination', 'entered_by', 'entry_method'],
                  'turned_around':      ['destination', 'entered_by', 'entry_method'],
                  'bus_codes':          ['name', 'code'],
                  'destination_codes':  ['name', 'code'],
                  'nps_approved_codes': ['name', 'code'],
                  'nps_work_groups':    ['name', 'code']
                  }
DEFAULT_VALUES = {'entry_method': "'manual'"}


UNIQUE_CONSTAINTS = {'bus_codes': ['code'],
                     'destination_codes': ['code'],
                     'nps_approved_codes': ['code'],
                     'nps_work_groups': ['code']
                     }

FOREIGN_KEYS = pd.DataFrame([{'l_table': 'accessibility',    'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'buses',            'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'buses',            'l_column': 'bus_type',    'f_table': 'bus_codes',         'f_column': 'code'},
                             {'l_table': 'employee_vehicles','l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'inholders',        'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'nps_approved',     'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'nps_approved',     'l_column': 'approved_type','f_table':'nps_approved_codes','f_column': 'code'},
                             {'l_table': 'nps_contractors',  'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'nps_vehicles',     'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'nps_vehicles',     'l_column': 'work_group',  'f_table': 'nps_work_groups',   'f_column': 'code'},
                             {'l_table': 'other_vehicles',   'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'photographers',    'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'subsistence',      'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'},
                             {'l_table': 'tek_campers',      'l_column': 'destination', 'f_table': 'destination_codes', 'f_column': 'code'}
                            ])


def main(info_txt):

    if not os.path.isfile(info_txt):
        raise IOError('info_txt does not exist: %s' % info_txt)

    # read connection params from text. Need to keep them in a text file because password can't be stored in Github repo
    connection_info = {}
    with open(info_txt) as txt:
        for line in txt.readlines():
            if ';' not in line:
                continue
            param_name, param_value = line.split(';')
            connection_info[param_name.strip()] = param_value.strip()

    for param in ['username', 'password', 'ip_address', 'port']:
        if param not in connection_info:
            raise NameError("missing param '%s' in connection info_txt: %s" % (param, info_txt))

    engine = create_engine('postgresql://{username}:{password}@{ip_address}:{port}/savage'.format(**connection_info))

    sql = ''  # Create an empty string
    # Add statements to alter all fields that should be integers
    for table, fields in INTEGER_FIELDS.iteritems():
        for field in fields:
            sql += 'ALTER TABLE IF EXISTS {table_name}' \
                   ' ALTER COLUMN {field} SET DATA TYPE integer' \
                   ' USING {field}::integer; '.format(table_name=table, field=field)


    # Add statements to alter all fields that should be text (string)
    for table, fields in VARCHAR_FIELDS.iteritems():
        for field in fields:
            sql += 'ALTER TABLE IF EXISTS {table_name}' \
                   ' ALTER COLUMN {field} SET DATA TYPE varchar(255)' \
                   ' USING {field}::text; '.format(table_name=table, field=field)
            if field in DEFAULT_VALUES:
                sql += 'ALTER TABLE IF EXISTS {table_name}' \
                       ' ALTER COLUMN {field} SET DEFAULT {value}; '\
                        .format(table_name=table, field=field, value=DEFAULT_VALUES[field])

    # Make changes to the DB
    """with engine.connect() as conn, conn.begin():
        print 'Submitting the following commands: \n%s\n' % sql.replace('; ', ';\n')
        #conn.execute(sql)

        # Set all numeric fields in inholder_allotments to int
        print 'Setting data types for integer fields in inholder_allotments table\n'
        result = conn.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'inholder_allotments';")

        for row in result:
            field = row['column_name']
            if field != 'permit_holder':
                '''conn.execute('ALTER TABLE inholder_allotments'
                             ' ALTER COLUMN {field} SET DATA TYPE integer'
                             ' USING {field}::integer;'
                             'ALTER TABLE inholder_allotments'
                             ' ALTER COLUMN {field} SET DEFAULT 0'.format(field=field))'''
                             """

    # Create unique constraints
    sql_template = "ALTER TABLE {table_name} ADD CONSTRAINT {table_name}_{column_name}_unique UNIQUE ({column_name})"
    sql_stmts = [sql_template.format(table_name=tname, column_name=cname)
                for tname in UNIQUE_CONSTAINTS for cname in UNIQUE_CONSTAINTS[tname]]
    for sql in sql_stmts:
        with engine.connect() as conn, conn.begin():
            try:
                conn.execute(sql)
            except sqlalchemy.exc.SQLAlchemyError as e:
                warnings.warn('unable to set constraint with statement %s because %s' % (sql, e.message))

    # Add foreign key constraints. Need to open and close with each iteration because if one fails, the rest do to until
    #   connection is closed.
    #   ON DELETE RESTRICT - don't delete any codes in the lookup table until all records with that code are gone
    #   ON UPDATE CASCADE - when changes are made in the lookup table, propagate changes to referencing columns
    for _, fkey_info in FOREIGN_KEYS.iterrows():
        sql = 'ALTER TABLE {local_table}' \
              ' ADD CONSTRAINT {local_col}_fkey' \
              ' FOREIGN KEY ({local_col})' \
              ' REFERENCES {foreign_table}({foreign_col})' \
              ' ON DELETE RESTRICT' \
              ' ON UPDATE CASCADE;'\
            .format(local_table=fkey_info.l_table, local_col=fkey_info.l_column,
                    foreign_table=fkey_info.f_table, foreign_col=fkey_info.f_column)

        try:
            with engine.connect() as conn, conn.begin():
                conn.execute(sql)
        except sqlalchemy.exc.SQLAlchemyError as e:
            warnings.warn("unable to set constraint with statement '%s' because '%s'" % (sql, e.message))

        # Add tablefunc extension
        #   can't do this if I want the user specified in connection_info.txt to not be a superuser (because whoever
        #   creates the table is the owner and anyone else needs superuser privileges to modify it)
        #   For more info: https://dba.stackexchange.com/a/175469
        #conn.execute('CREATE EXTENSION IF NOT EXISTS tablefunc;')


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

