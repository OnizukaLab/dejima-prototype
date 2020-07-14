import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import pprint

class Termination(object):
    def __init__(self, xid_list, db_conn_dict, child_peer_dict):
        self.xid_list = xid_list
        self.db_conn_dict = db_conn_dict
        self.child_peer_dict = child_peer_dict

    def on_post(self, req, resp):
        print("/termination start")
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {}
        current_xid = params['xid'] 
        db_conn = self.db_conn_dict[current_xid]
        print(db_conn)
        if params['result'] == "commit":
            for peer in self.child_peer_dict[current_xid]:
                url = "http://{}-proxy:8000/post_transaction".format(peer)
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "commit"
                }
                res = requests.post(url, json.dumps(data), headers=headers)
            db_conn.commit()
            print("result=commit", db_conn)
        elif params['result'] == "abort":
            for peer in self.child_peer_dict[current_xid]:
                url = "http://{}-proxy:8000/post_transaction".format(peer)
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "abort"
                }
                res = requests.post(url, json.dumps(data), headers=headers)
            db_conn.rollback()
            print("result=abort",db_conn)

        db_conn.close()
        msg["result"] = "Success"
        resp.body = json.dumps(msg)