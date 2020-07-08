import json
import falcon
from execution import Execution
from termination import Termination
import os

xid_list=[]
db_conn_dict={}
peer_name = os.environ['PEER_NAME']
app = falcon.API()
app.add_route("/post_transaction", Execution(xid_list, peer_name, db_conn_dict))
app.add_route("/terminate", Termination(xid_list, peer_name, db_conn_dict))

if __name__ == "__main__":
    from wsgiref import simple_server
    httpd = simple_server.make_server("0.0.0.0", 8000, app)
    httpd.serve_forever()