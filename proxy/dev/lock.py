import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Lock(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict, connection_pool):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict
        self.connection_pool = connection_pool

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        current_xid = params['xid']
        lineages = params['lineages']

        db_conn = self.connection_pool.getconn()
        self.tx_management_dict[current_xid] = {'db_conn': db_conn}
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            bt_list = self.dejima_config_dict['base_table'][self.peer_name]
            try: 
                for bt in bt_list:
                    for lineage in lineages:
                        cur.execute("SELECT * FROM {}_lineage WHERE lineage LIKE '%{}%' FOR UPDATE".format(bt, lineage))
                    # cur.execute("SELECT * FROM pgrowlocks('{}_lineage')".format(bt))
                    # print(cur.fetchall())
                msg = {"result": "Ack"}
            except Exception:
                msg = {"result": "Nak"}

        resp.body = json.dumps(msg)
        return