import json
import falcon
import os

with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)
peer_name = os.environ['PEER_NAME']
db_conn_dict={} # key: xid, value: database connection for each xid transaction.
child_peer_dict = {} # key: xid, value: set of child peers for each xid transaction.

app = falcon.API()

METHOD = "2PL"
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

if __name__ == "__main__":
    from wsgiref import simple_server
    httpd = simple_server.make_server("0.0.0.0", 8000, app)
    httpd.serve_forever()