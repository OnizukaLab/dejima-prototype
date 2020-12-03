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
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        if params['result'] == "commit":
            commit = True
        else:
            commit = False
        current_xid = params['xid']
        db_conn = self.tx_management_dict[current_xid]['db_conn']
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # termination 
            if commit:
                db_conn.commit()
                msg = {"result": "Ack"}
            else:
                db_conn.rollback()
                msg = {"result": "Nak"}

        resp.body = json.dumps(msg)
        del self.tx_management_dict[current_xid]
        return