import json
import psycopg2
from psycopg2.extras import DictCursor
import dejimautils
import requests
import sqlparse

class Execution(object):
    def __init__(self, peer_name, tx_management_dict, dejima_config_dict, connection_pool):
        self.peer_name = peer_name
        self.tx_management_dict = tx_management_dict
        self.dejima_config_dict = dejima_config_dict
        self.connection_pool = connection_pool

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {}
        current_xid = ""
        BASE_TABLE = "customer"

        db_conn = self.connection_pool.getconn()
        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            # get original TX's current_xid
            cur.execute("SELECT txid_current();")
            xid, *_ = cur.fetchone()
            current_xid = "{}_{}".format(self.peer_name, xid)
            self.tx_management_dict[current_xid] = {'db_conn': None, 'lock_peer_list': []} # no need to pool db_connection for root peer.

            # execute stmt and list up lineages
            lineages =  []
            inserted_lineages = []
            deleted_lineages = []
            query_results = {}
            for stmt in params['sql_statements']:
                # where clause extract
                stmt = sqlparse.format(stmt, keyword_case="upper")
                parsed_stmt = sqlparse.parse(stmt)
                where_clause = ""
                for token in parsed_stmt[0]:
                    if type(token) == sqlparse.sql.Where: where_clause=token.value; break

                if stmt.startswith("SELECT"):
                    table_names = dejimautils.extract_tables(stmt)
                    cur.execute("SELECT key FROM {} {}FOR SHARE NOWAIT".format(', '.join(table_names), where_clause))
                    slock_keys = []
                    for record in cur.fetchall():
                        slock_keys.append(record[0])
                    for key in slock_keys:
                        cur.execute("SELECT * FROM {}_lineage WHERE key={} FOR SHARE NOWAIT".format(', '.join(table_names), key))
                    cur.execute(stmt)
                    query_results['{}'.format(cur.query)] = cur.fetchall()

                elif stmt.startswith("UPDATE"):
                    table_names =  stmt.split()[1]
                    cur.execute("SELECT key FROM {} {}FOR SHARE NOWAIT".format(table_names, where_clause).replace(";", ""))
                    wlock_keys = []
                    for record in cur.fetchall():
                        wlock_keys.append(record[0])
                    for key in wlock_keys:
                        cur.execute("SELECT lineage FROM {}_lineage WHERE key={} FOR UPDATE NOWAIT".format(table_names, key))
                        for record in cur.fetchall():
                            lineages.append(record[0])
                    cur.execute(stmt)

                elif stmt.startswith("INSERT"):
                    cur.execute(stmt + " RETURNING key")
                    for key in cur.fetchall():
                        inserted_lineages.append("({}, '<{},{},{}>')".format(key[0], self.peer_name, BASE_TABLE, key[0]))

                elif stmt.startswith("DELETE"):
                    cur.execute(stmt + " RETURNING key")
                    for key in cur.fetchall():
                        deleted_lineages.append("{}".format(key[0]))
            
            # create or delete lineages locally
            if deleted_lineages != []:
                where_clause = "WHERE " +  ' OR '.join(['key={}'.format(key) for key in deleted_lineages])
                cur.execute("DELETE FROM {}_lineage {}".format(BASE_TABLE, where_clause))
            if inserted_lineages != []:
                values_clause = "VALUES " + ', '.join(inserted_lineages)
                cur.execute("INSERT INTO {}_lineage {}".format(BASE_TABLE, values_clause))

            # lock records in other peers with lineages
            all_peers = list(self.dejima_config_dict['peer_address'].keys())
            all_peers.remove(self.peer_name)
            result = dejimautils.lock_request_with_lineage(all_peers, lineages, current_xid, self.dejima_config_dict)
            if result != "Ack":
                dejimautils.termination_request(propagated_peers, "abort", current_xid, self.dejima_config_dict)
                msg = {"result": "abort"}
                db_conn.rollback()
                self.connection_pool.putconn(db_conn)
                msg = {"query_results": query_results}
                resp.body = json.dumps(msg)
                return

            # propagation
            propagated_peers = []
            commit = True
            for dt in self.dejima_config_dict['dejima_table'].keys():
                if self.peer_name not in self.dejima_config_dict['dejima_table'][dt]: continue
                cur.execute("SELECT public.{}_get_detected_update_data();".format(dt))
                delta, *_ = cur.fetchone()
                if delta != None:
                    target_peers = self.dejima_config_dict['dejima_table'][dt]
                    target_peers.remove(self.peer_name)
                    propagated_peers.extend(target_peers)
                    result = dejimautils.prop_request(target_peers, dt, delta, inserted_lineages, deleted_lineages, current_xid, self.dejima_config_dict)
                    if result != "Ack":
                        commit = False
                        break
            
            # termination 
            if commit:
                dejimautils.termination_request(propagated_peers, "commit", current_xid, self.dejima_config_dict)
                msg = {"result": "commit"}
                db_conn.commit()
            else:
                dejimautils.termination_request(propagated_peers, "abort", current_xid, self.dejima_config_dict)
                msg = {"result": "abort"}
                db_conn.rollback()

        self.connection_pool.putconn(db_conn)
        msg = {"query_results": query_results}
        resp.body = json.dumps(msg)
        del self.tx_management_dict[current_xid]
        return
