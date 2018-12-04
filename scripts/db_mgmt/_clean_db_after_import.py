import sys, os
from sqlalchemy import create_engine


INTEGER_FIELDS = {'buses':              ['n_passengers', 'n_wheelchair', 'n_lodge_ovrnt'],
                  'admin_use':          ['nps_vehicle_id'],
                  'gmp':                ['month', 'year', 'gmpcount'],
                  'cyclists':           ['n_passengers'],
                  'employee_vehicles':  ['n_passengers', 'permit_number'],
                  'nps_approved':       ['n_nights', 'n_passengers'],
                  'nps_contractors':    ['n_nights', 'n_passengers'],
                  'nps_vehicles':       ['n_nights', 'n_passengers'],
                  'photographers':      ['n_nights', 'n_passengers', 'permit_number'],
                  'inholders':           ['n_passengers', 'permit_number'],
                  'road_lottery':       ['n_passengers', 'permit_number'],
                  'subsistence':        ['n_passengers'],
                  'tek_campers':       ['n_passengers'],
                  'turned_around':      ['n_passengers']
                  }
TEXT_FIELDS = {'employee_vehicles':  ['driver_name'],
               'nps_approved':       ['driver_name'],
               'nps_contractors':    ['organization', 'trip_purpose'],
               'nps_vehicles':       ['driver_name', 'trip_purpose', 'work_division', 'work_group'],
               'photographers':      ['driver_name'],
               'inholders':          ['driver_name', 'permit_holder'],
               'subsistence':        ['driver_name']
               }



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
                   ' ALTER COLUMN {field} SET DATA TYPE bigint' \
                   ' USING {field}::bigint; '.format(table_name=table, field=field)

    # Add statements to alter all fields that should be text (string)
    for table, fields in TEXT_FIELDS.iteritems():
        for field in fields:
            sql += 'ALTER TABLE IF EXISTS {table_name}' \
                   ' ALTER COLUMN {field} SET DATA TYPE text' \
                   ' USING {field}::text; '.format(table_name=table, field=field)

    # Make changes to the DB
    with engine.connect() as conn, conn.begin():
        print 'Submitting the following commands: \n%s\n' % sql.replace('; ', ';\n')
        conn.execute(sql)

        # Set all numeric fields in inholder_allotments to int
        print 'Setting data types for integer fields in inholder_allotments table\n'
        result = conn.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'inholder_allotments';")

        for row in result:
            field = row['column_name']
            if field != 'permit_holder':
                conn.execute('ALTER TABLE inholder_allotments'
                             ' ALTER COLUMN {field} SET DATA TYPE bigint'
                             ' USING {field}::bigint;'.format(field=field))

        # Add tablefunc extension
        conn.execute('CREATE EXTENSION IF NOT EXISTS tablefunc;')


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))

