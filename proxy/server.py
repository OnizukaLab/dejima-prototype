import json
import falcon
from execution import Execution
from termination import Termination
from propagation import Propagation
import os

with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)
peer_name = os.environ['PEER_NAME']
db_conn_dict={} # key: xid, value: database connection for each xid transaction.
child_peer_dict = {} # key: xid, value: set of child peers for each xid transaction.

app = falcon.API()
app.add_route("/post_transaction", Execution(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
app.add_route("/_propagate", Propagation(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
app.add_route("/_terminate_transaction", Termination(db_conn_dict, child_peer_dict))

if __name__ == "__main__":
    from wsgiref import simple_server
    httpd = simple_server.make_server("0.0.0.0", 8000, app)
    httpd.serve_forever()