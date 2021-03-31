'''
author: Sam Hooper
contact: samuel_hooper@nps.gov
created on: 11/1/18

Write categories to stdout.

This script is intended to be run by Form_frm_query_plot.show_list_box() function in savage_frontend.accdb
to return a comma-separated list of the category options from the SORT_ORDER dictionary in
count_vehicles_by_type.py

'''

import sys
import pandas as pd

import query
import count_vehicles_by_type as cvbt


def get_nps_work_groups(connection_txt):

    engine = query.connect_db(connection_txt)

    with engine.connect() as conn, conn.begin():
        work_groups = pd.read_sql("SELECT DISTINCT work_group FROM nps_vehicles;", conn)\
            .squeeze() # Should only return one column so make it a Series

    return work_groups[~work_groups.isnull()].sort_values().tolist()

def main(query_name, connection_txt):

    all_categories = cvbt.SORT_ORDER

    if query_name not in all_categories:
        raise IOError("Name not found")

    category_names = {'summary': all_categories['summary'],
                      'buses': all_categories['buses'],
                      'pov': all_categories['pov'],
                      'nps': all_categories['nps'],#get_nps_work_groups(connection_txt),
                      'bikes': [" "],
                      'total': all_categories['summary']
                      }

    category_str = ';'.join(category_names[query_name])

    sys.stdout.write(category_str)
    sys.stdout.flush()


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))