import os, sys

import accessdb_to_csv
import _clean_tables_premerge
import merge_year_csvs
import _clean_tables_postmerge
import csvs_to_postgres
import _clean_db_after_import


ROOT_DIR = r'C:\Users\shooper\proj\savagedb\db'

def main():
    # Export from Access
    exported_dir = os.path.join(ROOT_DIR, 'exported_tables')
    accessdb_to_csv.main(exported_dir, search_dir=os.path.join(ROOT_DIR, 'original'))

    # Do everything possible before merging to clean tables
    _clean_tables_premerge.main()

    # Merge them
    merged_dir = os.path.join(ROOT_DIR, 'merged_tables')
    merge_year_csvs.main(exported_dir, merged_dir)

    # Do the rest of the stuff that has to happen post-merge
    _clean_tables_postmerge.main(os.path.join(merged_dir, 'cleaned'))

    # Import csvs to DB
    connection_txt = os.path.join(os.path.join(ROOT_DIR, '..'), 'connection_info.txt')
    csvs_to_postgres.main(os.path.join(os.path.join(merged_dir, 'cleaned')), connection_txt=connection_txt)

    # Clean up datatypes in DB
    _clean_db_after_import.main()


if __name__ == '__main__':
    sys.exit(main())
