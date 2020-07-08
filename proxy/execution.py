import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import pprint

class Execution(object):
    def __init__(self, xid_list, peer_name, db_conn_dict):
        self.xid_list = xid_list
        self.peer_name = peer_name
        self.db_conn_dict = db_conn_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)
            pprint.pprint(params)

        dejima_dict = {
            "dejima_1_2": ["Univ1", "Univ2"],
            "dejima_1_3": ["Univ1", "Univ3"]
        }
        dt_list = list(dejima_dict.keys())
        msg = {}
        current_xid = ""
        sql_statements = []

        # ----- Update type check (on Base table or Dejima table)
        if params['transaction_type'] == "propagation":
            # ----- xid check -----
            if params['xid'] in self.xid_list:
                msg = {"result": "Failed (detection loop)"}
                resp.body = json.dumps(msg)
                return
            else:
                current_xid = params['xid']
                self.xid_list.append(current_xid)
                dt_list.remove(params['dejima_table'])
                _, sql_statements = dejimautils.convert_to_sql_from_json(params['sql_statements'])
            
        # ----- transaction execution -----
        db_conn = psycopg2.connect("dbname=postgres user=dejima password=barfoo host={}-db port=5432".format(self.peer_name))
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            if params['transaction_type'] == "original":
                # note: psycopg2 doesn't need BEGIN statement. Transaction is valid as default.
                try:
                    cur.execute("SELECT txid_current();")
                    xid, *_ = cur.fetchone()
                    current_xid = "{}_{}".format(self.peer_name, xid)
                    self.xid_list.append(current_xid)
                except psycopg2.Error as e:
                    print(e)
                    msg = {"result": "Failed (cannot begin transaction"}
                    resp.body = json.dumps(msg)
                    db_conn.rollback()
                    return
            
                try:
                    query_results = {}
                    sql_statements = params['sql_statements']
                    for statement in sql_statements:
                        if statement.startswith("SELECT"):
                            statement.replace("SELECT", "SELECT FOR UPDATE")
                            cur.execute(statement)
                            query_results['{}'.format(cur.query)] = cur.fetchall()
                        else:
                            cur.execute(statement)
                    msg["query_results"] = query_results
                except psycopg2.Error as e:
                    print(e)
                    msg = {"result": "Failed (erro occur in pg)"}
                    resp.body = json.dumps(msg)
                    db_conn.rollback()
                    return

            elif params['transaction_type'] == 'propagation':
                try:
                    for statement in sql_statements:
                        cur.execute(statement)
                except psycopg2.Error as e:
                    print(e)
                    msg = {"result": "Failed (erro occur in pg)"}
                    resp.body = json.dumps(msg)
                    db_conn.rollback()
            
            self.db_conn_dict[current_xid] = db_conn
    
            for dt in dt_list:
                if self.peer_name in dejima_dict[dt]:
                    print("target dt: ", dt)
                    cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                    delta, *_ = cur.fetchone()
                    if delta != None:
                        for peer in dejima_dict[dt]:
                            if peer == self.peer_name:
                                continue
                            url = "http://{}-proxy:8000/post_transaction".format(peer)
                            headers = {"Content-Type": "application/json"}
                            data = {
                                "xid": current_xid,
                                "transaction_type": "propagation",
                                "dejima_table": dt,
                                "sql_statements": delta
                            }
                            print(data)
                            res = requests.post(url, json.dumps(data), headers=headers)
                            result = res.json()['result']
                            if result != "Success":
                                msg["result"] = "Failed (Child error)"
                                resp.body = json.dumps(msg)
                                db_conn.rollback()
                                return

        if params['transaction_type'] == "propagation":
            msg["result"] = "Success"
            resp.body = json.dumps(msg)
