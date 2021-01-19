import json
import falcon
import os
import psycopg2.pool
import sys
sys.dont_write_bytecode = True

with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)
peer_name = os.environ['PEER_NAME']
tx_management_dict={}
# tx_management_dict={"xid": {"db_conn": db_conn, "lock_peer_list": lock_peer_list, "child_peer_list": child_peer_list}, ...}
db_conn_dict={} # key: xid, value: database connection for each xid transaction.
child_peer_dict = {} # key: xid, value: set of child peers for each xid transaction.

while True:
    try:
        connection_pool = psycopg2.pool.SimpleConnectionPool(minconn=2, maxconn=5, host="{}-db".format(peer_name), port="5432", dbname="postgres", user="dejima", password="barfoo")
        break
    except Exception:
        pass

app = falcon.API()

METHOD = "dev"
if (METHOD=="2PL"):
    from two_pl.execution import Execution
    from two_pl.termination import Termination
    from two_pl.propagation import Propagation
    from two_pl.addition import Addition
    from two_pl.deletion import Deletion
    from two_pl.getting_list import GettingList
    app.add_route("/post_transaction", Execution(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
    app.add_route("/add_student", Addition(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
    app.add_route("/delete_student", Deletion(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
    app.add_route("/get_student_list", GettingList(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
    app.add_route("/_propagate", Propagation(peer_name, db_conn_dict, child_peer_dict, dejima_config_dict))
    app.add_route("/_terminate_transaction", Termination(db_conn_dict, child_peer_dict, dejima_config_dict))
elif (METHOD=="FRS_broadcast"):
    from frs_broadcast.execution import Execution
    from frs_broadcast.test import Test
    from frs_broadcast.propagation import Propagation
    from frs_broadcast.termination import Termination
    from frs_broadcast.lock import Lock
    app.add_route("/post_transaction", Execution(peer_name, tx_management_dict, dejima_config_dict, connection_pool))
    app.add_route("/_test", Test(peer_name, tx_management_dict, dejima_config_dict))
    app.add_route("/_propagate", Propagation(peer_name, tx_management_dict, dejima_config_dict))
    app.add_route("/_terminate", Termination(peer_name, tx_management_dict, dejima_config_dict, connection_pool))
    app.add_route("/_lock", Lock(peer_name, tx_management_dict, dejima_config_dict, connection_pool))
elif (METHOD=="FRS"):
    from frs.execution import Execution
    from frs.termination import Termination
    from frs.propagation import Propagation
    from frs.lock import Lock
    app.add_route("/post_transaction", Execution(peer_name, tx_management_dict, dejima_config_dict))
    app.add_route("/_propagate", Propagation(peer_name, tx_management_dict, dejima_config_dict))
    app.add_route("/_terminate", Termination(tx_management_dict, dejima_config_dict))
    app.add_route("/_lock", Lock(tx_management_dict, dejima_config_dict))
elif (METHOD=="dev"):
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