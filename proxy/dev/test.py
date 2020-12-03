import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Test(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        print("accepted data: {}".format(params))
        msg = {"result": "Ack"}
        resp.body = json.dumps(msg)
        return