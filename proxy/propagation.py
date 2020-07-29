import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Propagation(object):
    def __init__(self, peer_name, db_conn_dict, child_peer_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.db_conn_dict = db_conn_dict
        self.child_peer_dict = child_peer_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        dt_list = list(self.dejima_config_dict['dejima_table'].keys())
        msg = {"result": "commit"}
        xid_list = self.db_conn_dict.keys()
        current_xid = ""
        sql_statements = []
        child_peer_set = set([])

        # ----- xid check -----
        if params['xid'] in xid_list:
            msg = {"result": "Failed (loop detection)"}
            resp.body = json.dumps(msg)
            print("Propagated Tx: Failed (loop detection) (xid={})".format(params['xid']))
            return
        else:
            current_xid = params['xid']
            self.db_conn_dict[current_xid] = None
            _, sql_statements = dejimautils.convert_to_sql_from_json(params['sql_statements'])
            self.child_peer_dict[current_xid] = []
            
        # ----- connect to postgreSQL -----
        try:
            db_conn = psycopg2.connect("connect_timeout=1 dbname=postgres user=dejima password=barfoo host=Univ-db port=5432".format(self.peer_name))
        except Exception as e:
            msg = {"result": "Failed (cannot connect PostgreSQL)"}
            resp.body = json.dumps(msg)
            print("Propagated Tx: Failed (cannot connect PostgreSQL) (xid={})".format(current_xid))
            return

        # ----- execute transaction -----
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # save connection to database
            self.db_conn_dict[current_xid] = db_conn

            try:
                for statement in sql_statements:
                    cur.execute(statement)
            except psycopg2.Error as e:
                print(e)
                msg = {"result": "Failed (error in postgres)"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                print("Propagated Tx: Failed (error in postgres) (xid={})".format(current_xid))
                return

            # ----- propagation -----
            dt_list.remove(params['dejima_table'])
            for dt in dt_list:
                if self.peer_name in self.dejima_config_dict['dejima_table'][dt]:
                    cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                    delta, *_ = cur.fetchone()
                    if delta != None:
                        for peer in self.dejima_config_dict['dejima_table'][dt]:
                            if peer == self.peer_name:
                                continue
                            child_peer_set.add(peer)
                            url = "http://{}:8000/_propagate".format(self.dejima_config_dict['peer_address'][peer])
                            headers = {"Content-Type": "application/json"}
                            data = {
                                "xid": current_xid,
                                "dejima_table": dt,
                                "sql_statements": delta
                            }
                            try:
                                res = requests.post(url, json.dumps(data), headers=headers)
                                result = res.json()['result']
                                self.child_peer_dict[current_xid] = child_peer_set
                                if result != "Success":
                                    msg["result"] = "Failed (Child error)"
                                    resp.body = json.dumps(msg)
                                    print("Propagated Tx: Failed (child error) (xid={})".format(current_xid))
                                    return
                            except Exception as e:
                                print(e)
                                msg["result"] = "Failed (Child server is not found)"
                                resp.body = json.dumps(msg)
                                break
                        else:
                            continue
                        break

        # send "Success" and exit
        msg["result"] = "Success"
        resp.body = json.dumps(msg)
        return