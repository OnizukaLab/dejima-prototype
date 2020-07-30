import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Addition(object):
    def __init__(self, peer_name, db_conn_dict, child_peer_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.db_conn_dict = db_conn_dict
        self.child_peer_dict = child_peer_dict
        self.dejima_config_dict = dejima_config_dict

    def on_get(self, req, resp):
        params = req.params

        dt_list = list(self.dejima_config_dict['dejima_table'].keys())
        msg = {"result": "commit"}
        xid_list = self.db_conn_dict.keys()
        current_xid = ""
        sql_statements = []
        child_peer_set = set([])

        # ----- connect to postgreSQL -----
        try:
            db_conn = psycopg2.connect("connect_timeout=1 dbname=postgres user=dejima password=barfoo host={}-db port=5432".format(self.peer_name))
        except Exception as e:
            msg = {"result": "Failed (cannot connect PostgreSQL)"}
            resp.body = json.dumps(msg)
            print("Original Tx: Failed (cannot connect PostgreSQL) (xid=not assigned)")
            return

        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # note: psycopg2 doesn't need BEGIN statement. Transaction is valid as default.

            # get original TX's current_xid
            try:
                cur.execute("SELECT txid_current();")
                xid, *_ = cur.fetchone()
                current_xid = "{}_{}".format(self.peer_name, xid)
                self.db_conn_dict[current_xid] = None
                self.child_peer_dict[current_xid] = []
            except psycopg2.Error as e:
                print(e)
                msg = {"result": "Failed (cannot begin transaction"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                db_conn.close()
                print("Original Tx: Failed (cannot begin Tx) (xid=not assigned)")
                return
        
            # execute transaction
            try:
                query_results = {}
                statement = "INSERT INTO student VALUES ({}, '{}', '{}', '{}');".format(params['id'], params['university'], params['first_name'], params['last_name'])
                cur.execute(statement)
            except psycopg2.Error as e:
                print(e)
                msg = {"result": "Failed (error in postgres)"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                db_conn.close()
                del self.db_conn_dict[current_xid]
                print("Original Tx: Failed (error in postgres) (xid={})".format(current_xid))
                return
            except Exception as e:
                msg = {"result": "Failed (invalid parameter)"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                db_conn.close()
                del self.db_conn_dict[current_xid]
                print("Original Tx: Failed (invalid parameter) (xid={})".format(current_xid))
                return
    
            # propagation
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
                                res = requests.post(url, json.dumps(data), headers=headers, timeout=(1.0, 1.0))
                                result = res.json()['result']
                                self.child_peer_dict[current_xid] = child_peer_set
                                if result != "Success":
                                    msg["result"] = "Failed (Child error)"
                                    resp.body = json.dumps(msg)
                            except Exception as e:
                                print(e)
                                msg["result"] = "Failed (Child server is not found)"
                                resp.body = json.dumps(msg)
                                break
                        else:
                            continue
                        break

        # if not all results is "Success", then send "abort" to childs, and db_conn.close()
        # if all results is "Success", then send "commit" to childs. and db_conn.close()
        if msg["result"] != "commit":
            del msg["query_results"]
            resp.body = json.dumps(msg)
            for child in child_peer_set:
                url = "http://{}:8000/_terminate_transaction".format(self.dejima_config_dict['peer_address'][child])
                headers = {"Content-Type": "application/json"}
                data = {
                    "xid": current_xid,
                    "result": "abort"
                }
                try:
                    res = requests.post(url, json.dumps(data), headers=headers, timeout=(1.0, 1.0))
                except Exception as e:
                    continue
            db_conn.close()
        else:
            msg["result"] = "commit"
            resp.body = json.dumps(msg)
            for child in child_peer_set:
                url = "http://{}:8000/_terminate_transaction".format(self.dejima_config_dict['peer_address'][child])
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