import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Test(object):
    def __init__(self):
        pass

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {"result": "Ack"}
        resp.text = "true"
        return
    
    def on_get(self, req, resp):
        resp.text = "Ack"
        return