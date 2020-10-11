import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Execution(object):
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
        current_xid = ""
        child_peer_set = set([])

        # ----- connect to postgreSQL -----
        db_conn = psycopg2.connect("connect_timeout=1 dbname=postgres user=dejima password=barfoo host={}-db port=5432".format(self.peer_name))

        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # note: psycopg2 doesn't need BEGIN statement. Transaction is valid as default.

            # get original TX's current_xid
            cur.execute("SELECT txid_current();")
            xid, *_ = cur.fetchone()
            current_xid = "{}_{}".format(self.peer_name, xid)
            self.db_conn_dict[current_xid] = None # no need to pool db_connection for root peer.
            self.child_peer_dict[current_xid] = []
            sql_stmts = params['sql_statements']
            query_results = {}
        
            # execute transaction
            try:
                lock_stmts = dejimautils.convert_to_lock_stmts(sql_stmts)
                for stmt in lock_stmts:
                    print(stmt)
                    cur.execute(stmt)
                for stmt in sql_stmts:
                    cur.execute(stmt)
                    if stmt.startswith("SELECT"):
                        query_results['{}'.format(cur.query)] = cur.fetchall()
                msg["query_results"] = query_results
            except psycopg2.Error as e:
                print(e)
                msg = {"result": "Failed in local Tx execution"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                db_conn.close()
                del self.db_conn_dict[current_xid]
                return

            # propagation
            for dt in dt_list:
                cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                delta, *_ = cur.fetchone()
                if delta != None:
                    for peer in self.dejima_config_dict['dejima_table'][dt]:
                        if peer == self.peer_name:
                            continue
                        child_peer_set.add(peer)
                        url = "http://{}/_propagate".format(self.dejima_config_dict['peer_address'][peer])
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
                            if result != "ack":
                                msg["result"] = "Failed in a child server"
                                resp.body = json.dumps(msg)
                        except Exception as e:
                            print(e)
                            msg["result"] = "Failed to connect a child server"
                            resp.body = json.dumps(msg)
                            break
                    else:
                        continue
                    break

        # if not all results is "ack", then send "abort" to childs, and db_conn.close()
        # if all results is "ack", then send "commit" to childs. and db_conn.close()
        if msg["result"] != "commit":
            del msg["query_results"]
            resp.body = json.dumps(msg)
            for child in child_peer_set:
                url = "http://{}/_terminate_transaction".format(self.dejima_config_dict['peer_address'][child])
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "abort"
                }
                try:
                    res = requests.post(url, json.dumps(data), headers=headers)
                except Exception as e:
                    continue
            db_conn.close()
        else:
            resp.body = json.dumps(msg)
            for child in child_peer_set:
                url = "http://{}/_terminate_transaction".format(self.dejima_config_dict['peer_address'][child])
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "commit"
                }
                try:
                    res = requests.post(url, json.dumps(data), headers=headers, timeout=(1.0, 1.0))
                except Exception as e:
                    continue
            db_conn.commit()
            db_conn.close()
        
        del self.db_conn_dict[current_xid]