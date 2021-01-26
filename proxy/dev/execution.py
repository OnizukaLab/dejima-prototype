import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import sqlparse
import time

class Execution(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {}
        current_xid = params['xid']
        self.tx_management_dict[current_xid] = {"db_conn": None, "child_peer_list": []}

        BASE_TABLE = "bt"

        updated_dt = params['view'].split(".")[1]
        target_peers = list(self.dejima_config_dict['dejima_table'][updated_dt])
        target_peers.remove(self.peer_name)
        self.tx_management_dict[current_xid]["child_peer_list"].extend(target_peers)
        delta = {"view": params["view"], "insertions": params["insertions"], "deletions": params["deletions"]}

        result = dejimautils.prop_request(target_peers, updated_dt, delta, current_xid, self.peer_name, self.dejima_config_dict)
        
        if result == "Ack":
            resp.body = "true"
            return
        else:
            resp.body = "false"
            return