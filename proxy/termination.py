import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import pprint

class Termination(object):
    def __init__(self, xid_list, peer_name, db_conn_dict):
        self.xid_list = xid_list
        self.peer_name = peer_name
        self.db_conn_dict = db_conn_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        current_xid = params['xid'] 
        db_conn = self.db_conn_dict[current_xid]
        if params['result'] == "commit":
            db_conn.commit()
        elif params['result'] == "abort":
            db_conn.rollback()

        db_conn.close()
        msg["result"] = "Success"
        resp.body = json.dumps(msg)