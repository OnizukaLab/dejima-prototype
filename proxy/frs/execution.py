import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests

class Execution(object):
    def __init__(self, peer_name,tx_management_dict, dejima_config_dict):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {} # return message
        current_xid = ""

        db_conn = psycopg2.connect("connect_timeout=1 dbname=postgres user=dejima password=barfoo host={}-db port=5432".format(self.peer_name))
        with db_conn.cursor(cursor_factory=DictCursor) as cur:

            # get original TX's current_xid
            cur.execute("SELECT txid_current();")
            xid, *_ = cur.fetchone()
            current_xid = "{}_{}".format(self.peer_name, xid)
            self.tx_management_dict[current_xid] = {'db_conn': None, 'lock_peer_list': [], 'child_peer_list': []} # no need to pool db_connection for root peer.

            # r/w lock locally, and get oids for write lock.
            oids_list = []
            sql_stmts = params['sql_statements']
            stmts_dict = dejimautils.convert_to_lock_rwstmts(sql_stmts)
            rlock_stmts = stmts_dict["rlock_stmts"] 
            wlock_stmts = stmts_dict["wlock_stmts"] 
            for stmt in rlock_stmts:
                cur.execute(stmt)
            for stmt in wlock_stmts:
                cur.execute(stmt)
                oids = cur.fetchall()
                for oid in oids:
                    oids_list.append(oid[0])

            # get lineage from oids
            lineage_list = []
            where_clause = ""
            oid_stmt = "SELECT lineage FROM student_lineage WHERE "
            for oid in oids_list:
                where_clause = "rid = {} OR".format(oid)
            where_clause = where_clause[:-2]
            if where_clause != "":
                oid_stmt = "SELECT lineage FROM student_lineage WHERE {}".format(where_clause)
                cur.execute(oid_stmt)
                lineages = cur.fetchall()
                for lineage in lineages:
                    lineage_list.append(lineage[0])
            
            # lineage_list
            lineage_list = ["<a,b,c>", "<d,e,f>"]
            # lock request
            all_peers = list(self.dejima_config_dict['peer_address'].keys())
            all_peers.remove(self.peer_name)
            result = dejimautils.lock_request_with_lineage(all_peers, lineage_list, current_xid, self.dejima_config_dict)

            # execution locally
            query_results = {}
            try:
                for stmt in sql_stmts:
                    if stmt.startswith("SELECT"):
                        cur.execute(stmt)
                        query_results['{}'.format(cur.query)] = cur.fetchall()
                    elif stmt.startswith("INSERT"):
                        cur.execute(stmt+" RETURNING OID")
                        inserted_oids = cur.fetchall()
                        values = ""
                        for inserted_oid in inserted_oids:
                            values = values + "({}, '<{},student,{}>'), ".format(inserted_oid, self.peer_name, inserted_oid)
                        values = values[:-2]
                        cur.execute("INSERT INTO student_linage VALUES {}".format(values))
                    else:
                        cur.execute(stmt)
                    if query_results != {}:
                        msg["query_results"] = query_results
            except psycopg2.Error as e:
                print(e)
                msg = {"result": "Failed in local Tx execution"}
                resp.body = json.dumps(msg)
                db_conn.rollback()
                db_conn.close()
                del self.tx_management_dict[current_xid]
                return

            # propagation
            dt_list = self.dejima_config_dict['dejima_table'].keys()
            propagated_peers = []
            commit = True
            for dt in dt_list:
                if self.peer_name not in self.dejima_config_dict['dejima_table'][dt]: continue
                cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                delta, *_ = cur.fetchone()
                print(delta)
                if delta != None:
                    target_peers = self.dejima_config_dict['dejima_table'][dt]
                    target_peers.remove(self.peer_name)
                    propagated_peers.extend(target_peers)
                    result = dejimautils.prop_request(target_peers, dt, delta, current_xid, self.dejima_config_dict)
                    if result != "Ack":
                        commit = False
                        break
            
            # termination 
            if commit:
                dejimautils.termination_request(propagated_peers, "commit", current_xid, self.dejima_config_dict)
                msg = {"result": "commit"}
            else:
                dejimautils.termination_request(propagated_peers, "abort", current_xid, self.dejima_config_dict)
                msg = {"result": "abort"}

        resp.body = json.dumps(msg)
        return