import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import sqlparse
import time
import os
import config

class Execution(object):
    def __init__(self):
        pass

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {}
        current_xid = params['xid']
        config.tx_management_dict[current_xid] = {"db_conn": None, "child_peer_list": []}

        updated_dt = params['view'].split(".")[1]
        target_peers = list(config.dejima_config_dict['dejima_table'][updated_dt])
        target_peers.remove(config.peer_name)
        config.tx_management_dict[current_xid]["child_peer_list"].extend(target_peers)
        delta = {"view": params["view"], "insertions": params["insertions"], "deletions": params["deletions"]}

        result = dejimautils.prop_request(target_peers, updated_dt, delta, current_xid, config.peer_name, config.dejima_config_dict)
        
        if result == "Ack":
            resp.body = "true"
        else:
            resp.body = "false"
        
        return