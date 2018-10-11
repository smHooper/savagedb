import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime, timedelta


def connect_db(connection_txt):

    connection_info = {}
    with open(connection_txt) as txt:
        for line in txt.readlines():
            if ';' not in line:
                continue
            param_name, param_value = line.split(';')
            connection_info[param_name.strip()] = param_value.strip()

    try:
        engine = create_engine(
            'postgresql://{username}:{password}@{ip_address}:{port}/{db_name}'.format(**connection_info))
    except:
        message = '\n' + '\n\t'.join(['%s: %s' % (k, v) for k, v in connection_info.iteritems()])
        raise ValueError('could not establish connection with parameters:%s' % message)

    return engine


def query_field_names(engine):
    with engine.connect() as conn, conn.begin():
        sql = 'SELECT ' \
              ' table_name, ' \
              ' column_name ' \
              'FROM information_schema.columns ' \
              'WHERE table_schema = \'public\''
        field_names = pd.read_sql(sql, conn)
    field_names = {table_name: ', '.join([f for f in df.column_name if f not in ['index', 'id']])
                   for table_name, df in field_names.groupby('table_name')}

    return field_names


def simple_query(engine, table_name, year=None, field_names='*', summary_field='datetime', summary_stat='COUNT', other_criteria='', date_part='month', output_fields=None, sql=None, return_sql=False):

    # If year is given, set up the where clause to encompass the whole season
    if year:
        where_clause = 'WHERE datetime BETWEEN \'{year}-05-20\' AND \'{year}-09-15\''\
            .format(year=str(year))
    else:
        where_clause = ''

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    #   First check whether it's necessary to modify the statement
    modify_criteria = other_criteria.strip() and \
                      (not (other_criteria.lower().strip().startswith('and ') or
                            other_criteria.lower().strip().startswith('or '))) or \
                      (not other_criteria.lower().strip().startswith('where ') and where_clause)

    if modify_criteria:
        other_criteria = 'AND ' + other_criteria if year else 'WHERE ' + other_criteria

    where_clause += other_criteria

    if not sql:
        sql = 'SELECT \n' \
              '   extract({date_part} FROM datetime) AS {date_part}, \n' \
              '   {summary_stat}({summary_field}) AS {table_name} \n' \
              'FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n' \
              '{where_clause} \n' \
              'GROUP BY {date_part} \n' \
              'ORDER BY {date_part};' \
            .format(date_part= date_part,
                    summary_stat=summary_stat,
                    summary_field=summary_field,
                    table_name=table_name,
                    where_clause=where_clause,
                    field_names=field_names
                    )

    # Execute query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # transform data so months are columns and the only row is the thing we're counting
    counts = counts.set_index(date_part).T
    if not output_fields and date_part == 'month':
        output_fields = {5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep'}
    counts.rename(columns=output_fields, inplace=True)

    counts.index.name = 'vehicle_type'

    counts['total'] = counts.sum(axis=1)

    return (counts, sql) if return_sql else counts





def crosstab_query(engine, table_name, pivot_field, value_field, year=None, field_names='*', summary_stat='COUNT', dissolve_names={}, other_criteria='', date_part='month', output_fields='', sql=None, return_sql=False):

    # If year is given, set up the where clause to encompass the whole season
    if year:
        date_clause = 'AND datetime BETWEEN \'\'{year}-05-20\'\' AND \'\'{year}-09-15\'\' '\
            .format(year=str(year))
    else:
        date_clause = ''

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    #   First check whether it's necessary to modify the statement
    modify_criteria = other_criteria.strip() and \
                      not (other_criteria.lower().strip().startswith('and ') or
                           other_criteria.lower().strip().startswith('or '))
    if modify_criteria:
        other_criteria = 'AND ' + other_criteria

    where_clause = ('WHERE %s IS NOT NULL ' % pivot_field) + date_clause + other_criteria

    if date_part == 'month' and not output_fields:
        output_fields = '"vehicle_type" text, "May" int, "Jun" int, "Jul" int, "Aug" int, "Sep" int'

    if not sql:
        category_sql = 'SELECT DISTINCT extract({date_part} FROM datetime) FROM {table_name} {where_clause} ORDER BY 1'\
            .format(date_part=date_part, table_name=table_name, where_clause=where_clause)

        sql = "SELECT * FROM crosstab(\n" \
              "'SELECT \n" \
              "   {pivot_field} AS vehicle_type, \n" \
              "   extract({date_part} FROM datetime), \n" \
              "   {summary_stat}({value_field}) \n" \
              "  FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n" \
              "  {where_clause} \n" \
              "  GROUP BY {pivot_field}, extract({date_part} FROM datetime) ORDER BY 1', \n" \
              "'{category_sql}'\n" \
              ") AS ({output_fields});" \
            .format(summary_stat=summary_stat,
                    value_field=value_field,
                    pivot_field=pivot_field,
                    date_part=date_part,
                    table_name=table_name,
                    field_names=field_names,
                    where_clause=where_clause,
                    category_sql=category_sql,
                    output_fields=output_fields
                    )
    # Execture query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # Combine vehicle types as necessary
    counts.set_index(counts.columns[0], inplace=True) # should always be first column
    for out_name, in_names in dissolve_names.iteritems():
        in_names = [n for n in in_names if n in counts.index]
        counts.loc[out_name] = counts.loc[in_names].sum(axis=0)
        counts.drop(in_names, inplace=True)
    counts['total'] = counts.sum(axis=1)

    return (counts, sql) if return_sql else counts
