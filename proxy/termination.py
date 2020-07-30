import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Termination(object):
    def __init__(self, db_conn_dict, child_peer_dict, dejima_config_dict):
        self.db_conn_dict = db_conn_dict
        self.child_peer_dict = child_peer_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {}
        current_xid = params['xid'] 
        db_conn = self.db_conn_dict[current_xid]
        del self.db_conn_dict[current_xid]

        if params['result'] == "commit":
            for peer in self.child_peer_dict[current_xid]:
                url = "http://{}:8000/_terminate_transaction".format(self.dejima_config_dict['peer_address'][peer])
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "commit"
                }
                try:
                    res = requests.post(url, json.dumps(data), headers=headers)
                except:
                    continue
            db_conn.commit()
        elif params['result'] == "abort":
            for peer in self.child_peer_dict[current_xid]:
                url = "http://{}:8000/_terminate_transaction".format(self.dejima_config_dict['peer_address'][peer])
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "abort"
                }
                try:
                    res = requests.post(url, json.dumps(data), headers=headers)
                except:
                    continue
            if db_conn != None:
                db_conn.rollback()

        if db_conn != None:
            db_conn.close()
        msg["result"] = "Success"
        resp.body = json.dumps(msg)