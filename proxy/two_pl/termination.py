import json
import dejimautils
import datetime
import config

class Termination(object):
    def __init__(self):
        pass

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        msg = {"result": "Ack"}
        if params['result'] == "commit":
            commit = True
        else:
            commit = False
        current_xid = params['xid']
        if not current_xid.startswith(config.peer_name):
            db_conn = config.connection_pool.getconn(key=current_xid)
            # termination 
            if commit:
                db_conn.commit()
                msg = {"result": "Ack"}
            else:
                db_conn.rollback()
                msg = {"result": "Nak"}
            config.connection_pool.putconn(db_conn, key=current_xid, close=True)

        target_tx_keys = [key for key in config.tx_management_dict.keys() if key.startswith(current_xid)]
        target_list = []
        for target_key in target_tx_keys:
            target_list.extend(config.tx_management_dict[target_key]['child_peer_list'])
            del config.tx_management_dict[target_key]

        target_list = list(set(target_list))
        if target_list != []:
            if commit: 
                dejimautils.termination_request(target_list, "commit", current_xid, config.dejima_config_dict) 
            else:
                dejimautils.termination_request(target_list, "abort", current_xid, config.dejima_config_dict) 

        resp.body = json.dumps(msg)
        print("termination finished")
        return