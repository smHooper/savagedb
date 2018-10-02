import pandas as pd


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


def simple_query(engine, table_name, year, field_names='*', summary_field='datetime', summary_stat='COUNT', other_criteria='', date_part='month'):

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    modify_criteria = other_criteria.strip() and \
                      not (other_criteria.lower().strip().startswith('and ') or
                           other_criteria.lower().strip().startswith('or '))
    if modify_criteria:
        other_criteria = 'AND ' + other_criteria

    sql = 'SELECT ' \
          '   extract({date_part} FROM datetime) AS {date_part}, ' \
          '   {summary_stat}({summary_field}) AS {table_name} ' \
          'FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} ' \
          'WHERE datetime BETWEEN \'{year}-05-20\' AND \'{year}-09-15\' ' \
          '{other_criteria} ' \
          'GROUP BY extract(month FROM datetime);' \
        .format(**{'date_part': date_part,
                   'summary_stat': summary_stat,
                   'summary_field': summary_field,
                   'table_name': table_name,
                   'field_names': field_names,
                   'year': str(year),
                   'other_criteria': other_criteria}
                )
    # Execute query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # transform data so months are columns and the only row is the thing we're counting
    counts = counts.set_index('month').T
    counts.rename(columns={5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep'}, inplace=True)
    counts.index.name = 'vehicle_type'

    counts['total'] = counts.sum(axis=1)

    return counts


def crosstab_query(engine, table_name, pivot_field, value_field, year, field_names='*', summary_stat='COUNT', dissolve_names={}, other_criteria='', date_part='month'):

    # Make sure other_criteria is prepended with AND unless the string is null
    if other_criteria.strip() and not other_criteria.lower().strip().startswith('and '):
        other_criteria = 'AND ' + other_criteria

    sql = 'SELECT * FROM crosstab(' \
          '\'SELECT ' \
          '   {pivot_field} AS vehicle_type, ' \
          '   extract({date_part} FROM datetime), ' \
          '   {summary_stat}({value_field}) ' \
          '  FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} ' \
          '  WHERE {pivot_field} IS NOT NULL ' \
          '  AND datetime BETWEEN \'\'{year}-05-20\'\' AND \'\'{year}-09-15\'\' ' \
          '  {other_criteria} ' \
          '  GROUP BY {pivot_field}, extract(month FROM datetime) ORDER BY 1\', ' \
          '\'SELECT m from generate_series(5,9) m \'' \
          ') AS ("vehicle_type" text, "May" int, "Jun" int, "Jul" int, "Aug" int, "Sep" int);' \
        .format(**{'summary_stat': summary_stat,
                   'value_field': value_field,
                   'pivot_field': pivot_field,
                   'date_part': date_part,
                   'table_name': table_name,
                   'field_names': field_names,
                   'year': str(year),
                   'other_criteria': other_criteria
                   }
                )
    # Execture query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # Combine vehicle types as necessary
    counts.set_index('vehicle_type', inplace=True)
    for out_name, in_names in dissolve_names.iteritems():
        in_names = [n for n in in_names if n in counts.index]
        counts.loc[out_name] = counts.loc[in_names].sum(axis=0)
        counts.drop(in_names, inplace=True)
    counts['total'] = counts.sum(axis=1)

    return counts