import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Termination(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict, connection_pool):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict
        self.connection_pool = connection_pool

    def on_post(self, req, resp):
        print("/terminate start")
        if req.content_length:
            body = req.bounded_stream.read()
            print("body: ", body)
            params = json.loads(body)

        msg = {"result": "Ack"}
        if params['result'] == "commit":
            commit = True
        else:
            commit = False
        current_xid = params['xid']
        if not current_xid.startswith(self.peer_name):
            try:
                db_conn = self.tx_management_dict[current_xid]['db_conn']
                with db_conn.cursor(cursor_factory=DictCursor) as cur:
                    # termination 
                    if commit:
                        db_conn.commit()
                        msg = {"result": "Ack"}
                    else:
                        db_conn.rollback()
                        msg = {"result": "Nak"}
                self.connection_pool.putconn(db_conn)
            except Exception as e:
                print(e)

        target_tx_keys = [key for key in self.tx_management_dict.keys() if key.startswith(current_xid)]
        target_list = []
        for target_key in target_tx_keys:
            target_list.extend(self.tx_management_dict[target_key]['child_peer_list'])
            del self.tx_management_dict[target_key]
        target_list = list(set(target_list))
        print("termination_request start")
        if commit: 
            dejimautils.termination_request(target_list, "commit", current_xid, self.dejima_config_dict) 
        else:
            dejimautils.termination_request(target_list, "abort", current_xid, self.dejima_config_dict) 
        print("termination_request completed")

        resp.body = json.dumps(msg)
        print("/terminate finish")
        return