#!/usr/bin/env python3
import argparse
import psycopg2
import sys
import time


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_host', required=True)
    arg_parser.add_argument('--db_port', required=True)
    arg_parser.add_argument('--db_user', required=True)
    arg_parser.add_argument('--db_password', required=True)
    arg_parser.add_argument('--timeout', type=int, default=5)

    args = arg_parser.parse_args()

    start_time = time.time()
    while (time.time() - start_time) < args.timeout:
        try:
            conn = psycopg2.connect(user=args.db_user, host=args.db_host, port=args.db_port, password=args.db_password, dbname='postgres')
            error = ''
        except psycopg2.OperationalError as e:
            error = e
        else:
            cursor = conn.cursor()
            cursor.execute("SELECT datname FROM pg_catalog.pg_database WHERE datistemplate = false AND datname<>'postgres'")
            dbs = cursor.fetchall()
            print("Db list: %s" % dbs, file=sys.stderr)
            cursor.close()
            conn.close()
            for db in dbs:
                db = db[0]
                if not ('-prod' in db):
                    print("Neutralizing database: %s" % db, file=sys.stderr)
                    conn = psycopg2.connect(user=args.db_user, host=args.db_host, port=args.db_port, password=args.db_password, dbname=db)
                    cursor = conn.cursor()
                    cursor.execute("DELETE FROM ir_config_parameter WHERE key = 'database.enterprise_code'")
                    cursor.execute("UPDATE ir_cron SET active = 'f'")
                    cursor.execute("UPDATE ir_config_parameter SET value='2050-01-01' WHERE key = 'database.expiration_date'")
                    cursor.execute("UPDATE ir_mail_server SET active = 'f'")
                    cursor.execute("DELETE FROM ir_config_parameter WHERE key IN ('ocn.ocn_push_notification','odoo_ocn.project_id', 'ocn.uuid')")
                    conn.commit()
                    cursor.close()
                    conn.close()
            break
        time.sleep(1)

    if error:
        print("Database connection failure: %s" % error, file=sys.stderr)
        sys.exit(1)
