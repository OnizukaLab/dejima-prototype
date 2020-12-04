import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import sqlparse

class Propagation(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        print("Accepted data: ", params)
        msg = {}
        current_xid = ""
        BASE_TABLE = "customer"

        current_xid = params['xid']
        db_conn = self.tx_management_dict[current_xid]['db_conn']
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # create or delete additional lineages
            deleted_lineages = params['deleted_lineages']
            inserted_lineages = params['inserted_lineages']
            if deleted_lineages != []:
                where_clause = "WHERE " +  ' OR '.join(['key={}'.format(key) for key in deleted_lineages])
                cur.execute("DELETE FROM {}_lineage {}".format(BASE_TABLE, where_clause))
            if inserted_lineages != []:
                values_clause = "VALUES " + ', '.join(inserted_lineages)
                cur.execute("INSERT INTO {}_lineage {}".format(BASE_TABLE, values_clause))

            # apply delta
            dt, stmts = dejimautils.convert_to_sql_from_json(params['delta'])
            for stmt in stmts:
                cur.execute(stmt)
            cur.execute("SET CONSTRAINTS ALL IMMEDIATE")

            msg = {"result": "Ack"}
            dt_list = list(self.dejima_config_dict['dejima_table'].keys())
            dt_list.remove(dt)
            for dt in dt_list:
                if self.peer_name not in self.dejima_config_dict['dejima_table'][dt]: continue
                cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                delta, *_ = cur.fetchone()
                if delta != None:
                    target_peers = list(self.dejima_config_dict['dejima_table'][dt])
                    target_peers.remove(self.peer_name)
                    print("before prop_request, target_peers", target_peers)
                    result = dejimautils.prop_request(target_peers, dt, delta, inserted_lineages, deleted_lineages, current_xid, self.dejima_config_dict)
                    print("after prop_request")
                    if result != "Ack":
                        msg = {"result": "Nak"}
                        break
            
        resp.body = json.dumps(msg)
        return
