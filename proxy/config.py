# peer_name : peer's name
# tx_management_dict : dictionary object for managing transaction
# e.g. {"xid": {"db_conn": db_conn, "lock_peer_list": lock_peer_list, "child_peer_list": child_peer_list}, ...}
# dejima_config_dict : dictionary object for describing peer's configuration
# connection_pool : connection pool for postgreSQL with psycopg2

import os
import json
import psycopg2.pool
import sys
sys.dont_write_bytecode = True

peer_name = os.environ['PEER_NAME']
tx_management_dict = {}
with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)

while True:
    try: 
        connection_pool = psycopg2.pool.ThreadedConnectionPool(minconn=50, maxconn=50, host="{}-db".format(peer_name), port="5432", dbname="postgres", user="dejima", password="barfoo")
        break
    except Exception:
        pass