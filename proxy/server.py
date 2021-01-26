import json
import falcon
import os
import psycopg2.pool
import sys
sys.dont_write_bytecode = True

peer_name = os.environ['PEER_NAME']
tx_management_dict = {}
with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)
# tx_management_dict={"xid": {"db_conn": db_conn, "lock_peer_list": lock_peer_list, "child_peer_list": child_peer_list}, ...}

while True:
    try: 
        connection_pool = psycopg2.pool.SimpleConnectionPool(minconn=2, maxconn=5, host="{}-db".format(peer_name), port="5432", dbname="postgres", user="dejima", password="barfoo")
        break
    except Exception:
        pass


app = falcon.API()

METHOD = "dev"
if (METHOD=="dev"):
    from dev.execution import Execution
    from dev.propagation import Propagation
    from dev.termination import Termination
    from dev.test import Test
    app.add_route("/execute", Execution(peer_name, tx_management_dict, dejima_config_dict))
    app.add_route("/_propagate", Propagation(peer_name, tx_management_dict, dejima_config_dict, connection_pool))
    app.add_route("/terminate", Termination(peer_name, tx_management_dict, dejima_config_dict, connection_pool))
    app.add_route("/_test", Test(peer_name, tx_management_dict, dejima_config_dict))

if __name__ == "__main__":
    from wsgiref import simple_server
    httpd = simple_server.make_server("0.0.0.0", 8000, app)
    httpd.serve_forever()