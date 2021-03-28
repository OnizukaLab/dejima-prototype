import json
from psycopg2.extras import DictCursor
import dejimautils
import config

class Propagation(object):
    def __init__(self):
        pass

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {"result": "Ack"}
        BASE_TABLE = "bt"
        current_xid = "_".join(params['xid'].split("_")[0:2])

        db_conn = config.connection_pool.getconn(key=current_xid)
        if current_xid in config.tx_management_dict.keys():
            resp.body = json.dumps({"result": "Nak"})
            config.connection_pool.putconn(db_conn, key=current_xid)
            return
        config.tx_management_dict[current_xid] = {'child_peer_list': []}

        with db_conn.cursor(cursor_factory=DictCursor) as cur:
            lock_ids = []
            delta = params['delta']
            insertion_records = delta["insertions"]
            deletion_records = delta["deletions"]
            for record in insertion_records:
                lock_ids.append(record['id'])
            for record in deletion_records:
                lock_ids.append(record['id'])
            lock_ids = set(lock_ids)

            try:
                for lock_id in lock_ids:
                    cur.execute("SELECT * FROM {}_lineage WHERE id={} FOR UPDATE NOWAIT".format(BASE_TABLE, lock_id))

                dt, stmts = dejimautils.convert_to_sql_from_json(params['delta'])
                for stmt in stmts:
                    cur.execute(stmt)
                cur.execute("SELECT {}_propagate_updates()".format(dt))
            except Exception as e:
                print("DB ERROR: ", e)
                resp.body = json.dumps({"result": "Nak"})
                return

            dt_list = list(config.dejima_config_dict['dejima_table'].keys())
            dt_list.remove(dt)
            for dt in dt_list:
                if config.peer_name not in config.dejima_config_dict['dejima_table'][dt]: continue
                target_peers = list(config.dejima_config_dict['dejima_table'][dt])
                target_peers.remove(config.peer_name)
                if params["parent_peer"] in target_peers: target_peers.remove(params["parent_peer"])
                if target_peers != []:
                    cur.execute("SELECT {}_propagate_updates_to_{}()".format(BASE_TABLE, dt))
                    cur.execute("SELECT public.{}_get_detected_update_data()".format(dt))
                    delta, *_ = cur.fetchone()
                    if delta != None:
                        delta = json.loads(delta)
                        print(delta)
                        config.tx_management_dict[current_xid]["child_peer_list"].extend(target_peers)
                        result = dejimautils.prop_request(target_peers, dt, delta, current_xid, config.peer_name, config.dejima_config_dict)
                        if result != "Ack":
                            msg = {"result": "Nak"}
                            break

        resp.body = json.dumps(msg)
        return