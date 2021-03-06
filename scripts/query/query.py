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
        message = '\n\t' + '\n\t'.join(['%s: %s' % (k, v) for k, v in connection_info.iteritems()])
        raise ValueError('could not establish connection with parameters:%s' % message)

    return engine


def query_field_names(engine):
    with engine.connect() as conn, conn.begin():
        sql = "SELECT " \
              " table_name, " \
              " column_name " \
              "FROM information_schema.columns " \
              "WHERE table_schema = 'public'"
        field_names = pd.read_sql(sql, conn)
    field_names = {table_name: ', '.join([f for f in df.column_name if f not in ['index', 'id']])
                   for table_name, df in field_names.groupby('table_name')}

    return field_names


def get_lookup_table(engine, table, index_col='code', value_col='name'):
    ''' Return a dictionary of code: name pairs from a given lookup table'''

    LOOKUP_TABLES = {'destinations': 'destination_codes',
                     'buses': 'bus_codes',
                     'approved': 'nps_approved_codes',
                     'work_groups': 'nps_work_groups'}

    with engine.connect() as conn, conn.begin():
        sql = "SELECT DISTINCT table_name FROM information_schema.tables WHERE table_schema = 'public';"
        table_names = pd.read_sql(sql, conn).squeeze()

        if table in LOOKUP_TABLES:
            table = LOOKUP_TABLES[table]
        if table in table_names.values:
            data = pd.read_sql("SELECT * FROM %s" % table, conn)
        else:
            table_options = '\n\t\t'.join(sorted(table_names.tolist() + LOOKUP_TABLES.keys()))
            raise ValueError('Table named "%s" not found. Options:\n\t\t%s"' % (table, table_options))

    if index_col not in data.columns:
        raise ValueError('index_col "%s" not found in table columns: %s' % (index_col, ', '.join(data.columns)))
    if value_col not in data.columns:
        raise ValueError('value_col "%s" not found in table columns: %s' % (value_col, ', '.join(data.columns)))

    data.set_index(index_col, inplace=True)

    return data[value_col].to_dict()


def filter_output_fields(filter_sql, engine, output_fields):

    with engine.connect() as conn, conn.begin():
        actual_fields = pd.read_sql(filter_sql, conn) #should return a df with only 1 column

    if len(actual_fields) == 0:
        return pd.Series()

    field_column_name = actual_fields.columns[0]
    actual_fields[field_column_name] = actual_fields[field_column_name].dt.strftime('%Y-%m-%d %H:%M:%S')
    matches = pd.merge(pd.DataFrame(output_fields, columns=['field_name']), actual_fields,
                       left_index=True, right_on=field_column_name, how='inner')

    return matches.set_index(field_column_name).sort_index().squeeze(axis=1) #type: pd.Series


def simple_query(engine, table_name, year=None, field_names='*', summary_field='datetime', summary_stat='COUNT', other_criteria='', summarize_by='year', output_fields=None, get_totals=True, sql=None, return_sql=False, start_time=None, end_time=None):

    # If year is given, set up the where clause to encompass the whole season
    if year:
        where_clause = 'WHERE datetime::date BETWEEN \'{year}-05-20\' AND \'{year}-09-15\''\
            .format(year=str(year))
    else:
        where_clause = ''

    time_clause = ""
    if start_time and end_time:
        try:
            datetime.strptime(start_time, '%H:%M')
            datetime.strptime(end_time, '%H:%M')
        except:
            raise ValueError("start_time and end_time must be in the format 'hh:mm'")
        time_clause = "AND datetime::time BETWEEN '{start_time}' AND '{end_time}'"\
            .format(start_time=start_time, end_time=end_time)

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    #   First check whether it's necessary to modify the statement
    modify_criteria = other_criteria.strip() and \
                      (not (other_criteria.lower().strip().startswith('and ') or
                            other_criteria.lower().strip().startswith('or '))) or \
                      (not other_criteria.lower().strip().startswith('where ') and where_clause)

    if modify_criteria:
        other_criteria = 'AND ' + other_criteria if year else 'WHERE ' + other_criteria

    where_clause += other_criteria + time_clause

    # Set the statement to use for creating categories to pivot on, datestamps truncated to the specified time step
    if summarize_by == 'halfhour':
        date_trunc_stmt = 'to_timestamp(FLOOR(EXTRACT(epoch FROM datetime::TIMESTAMPTZ)' \
                          '/1800) * 1800)::TIMESTAMP' #1800 == seconds in half hour
    else:
        date_trunc_stmt = "date_trunc('%s', datetime)::TIMESTAMP" % summarize_by

    if not sql:
        sql = 'SELECT \n' \
              '   {date_trunc_stmt} AS {summarize_by}, \n' \
              '   {summary_stat}({summary_field}) AS {table_name} \n' \
              'FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n' \
              '{where_clause} \n' \
              'GROUP BY {summarize_by} \n' \
              'ORDER BY {summarize_by};' \
            .format(date_trunc_stmt=date_trunc_stmt,
                    summarize_by=summarize_by,
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
    counts = counts.set_index(summarize_by).T
    if not pd.Series(output_fields).any() and summarize_by == 'month':
        output_fields = {5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug', 9: 'Sep'}

    if counts.shape[1] > 0:
        counts.columns = counts.columns.strftime('%Y-%m-%d %H:%M:%S') # read_sql() reads them as datetime
        counts.rename(columns=output_fields, inplace=True)

    counts.index.name = 'vehicle_type'

    if get_totals:
        counts['total'] = counts.sum(axis=1)

    return (counts, sql) if return_sql else counts


def crosstab_query(engine, table_name, start_str, end_str, pivot_field, summary_field='datetime', other_criteria='', field_names='*', summary_stat='COUNT', summarize_by='year', output_fields=[], dissolve_names={}, return_sql=False, get_totals=True, sql = None, filter_fields=False, start_time=None, end_time=None):

    date_clause = "AND datetime::date BETWEEN ''{start_str}'' AND ''{end_str}'' " \
        .format(start_str=start_str, end_str=end_str)

    time_clause = ""
    if start_time and end_time:
        try:
            datetime.strptime(start_time, '%H:%M')
            datetime.strptime(end_time, '%H:%M')
        except:
            raise ValueError("start_time and end_time must be in the format 'hh:mm'")
        time_clause = " AND datetime::time BETWEEN ''{start_time}'' AND ''{end_time}''"\
            .format(start_time=start_time, end_time=end_time)

    # Make sure other_criteria is prepended with AND unless the string is null or starts with 'OR'
    #   First check whether it's necessary to modify the statement
    modify_criteria = other_criteria.strip() and \
                      not (other_criteria.lower().strip().startswith('and ') or
                           other_criteria.lower().strip().startswith('or '))
    if modify_criteria:
        other_criteria = 'AND ' + other_criteria

    where_clause = ('WHERE %s IS NOT NULL ' % pivot_field) + date_clause + time_clause + other_criteria

    # Set the statement to use for creating categories to pivot on, datestamps truncated to the specified time step
    if summarize_by == 'halfhour':
        date_trunc_stmt = 'to_timestamp(FLOOR(EXTRACT(epoch FROM datetime::TIMESTAMPTZ)' \
                          '/1800) * 1800)::TIMESTAMP' #1800 == seconds in half hour
    else:
        date_trunc_stmt = "date_trunc(''%s'', datetime)::TIMESTAMP" % summarize_by

    sql_output_fields = output_fields.copy()
    if filter_fields:
        filter_sql = "SELECT DISTINCT {date_trunc_stmt} FROM {table_name} {where_clause};"\
            .format(date_trunc_stmt=date_trunc_stmt, table_name=table_name, where_clause=where_clause)\
            .replace("''", "'")
        sql_output_fields = filter_output_fields(filter_sql, engine, output_fields)

        if not sql_output_fields.any():
            empty_df = pd.DataFrame(columns=output_fields)
            return  empty_df, 'No SQL run because all fields were null' if return_sql else empty_df


    category_str = "VALUES (''" + ("''), (''".join(sql_output_fields.index)) + "'')"
    output_fields_str = 'vehicle_type text, ' + (' int, '.join(sql_output_fields)) + ' int'

    # set end date back 1 day because it had to be set forward 1 day for the BETWEEN part of WHERE clauses
    end_str = datetime.strftime(datetime.strptime(end_str, '%Y-%m-%d %H:%M:%S') - timedelta(days=1),
                                '%Y-%m-%d %H:%M:%S')
    if not sql:
        sql = "SELECT * FROM crosstab( \n" \
              "'SELECT \n" \
              "     {pivot_field}, \n" \
              "     {date_trunc_statement} AS {summarize_by}, \n" \
              "     {summary_stat}({summary_field}) \n" \
              "FROM (SELECT DISTINCT {field_names} FROM {table_name}) AS {table_name} \n" \
              "{where_clause} \n" \
              "GROUP BY {summarize_by}, {pivot_field}  ORDER BY 1', \n" \
              "'SELECT categories::TIMESTAMP FROM ({category_str}) AS t (categories) ORDER BY 1'\n" \
              ") AS ({output_fields_str});" \
            .format(pivot_field=pivot_field,
                    summary_field=summary_field,
                    date_trunc_statement=date_trunc_stmt,
                    summarize_by=summarize_by,
                    summary_stat=summary_stat,
                    table_name=table_name,
                    field_names=field_names,
                    where_clause=where_clause,
                    category_str=category_str,#interval='30 minute' if summarize_by == 'halfhour' else '1 %s' % summarize_by,
                    output_fields_str=output_fields_str
                    )

    # Execture query
    with engine.connect() as conn, conn.begin():
        counts = pd.read_sql(sql, conn)

    # Combine vehicle types as necessary
    counts.set_index(counts.columns[0], inplace=True) # should always be first column

    for out_name, in_names in dissolve_names.iteritems():
        in_names = [n for n in in_names if n in counts.index]
        counts.loc[out_name] = counts.loc[in_names].sum(axis=0)
        counts.drop(in_names, inplace=True)#'''
    '''if len(dissolve_names):
        counts['vehicle_type'] = pd.Series(dissolve_names)
        counts.set_index('vehicle_type', inplace=True)'''

    if not filter_fields:
        # Make sure all fields (i.e. dates/times) are returned
        counts = counts.reindex(columns=output_fields)

    if get_totals:
        counts['total'] = counts.sum(axis=1)

    return (counts, sql) if return_sql else counts