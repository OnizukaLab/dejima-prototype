import json
import dejimautils
import os
import config
import datetime

class Execution(object):
    def __init__(self):
        pass

    def on_post(self, req, resp):
        if req.content_length:
            body = req.bounded_stream.read()
            params = json.loads(body)

        updated_dt = params['view'].split(".")[1]
        current_xid = config.peer_name + "_" + params['xid'] + "_" + updated_dt

        config.tx_management_dict[current_xid] = {"db_conn": None, "child_peer_list": []}

        target_peers = list(config.dejima_config_dict['dejima_table'][updated_dt])
        target_peers.remove(config.peer_name)
        config.tx_management_dict[current_xid]["child_peer_list"].extend(target_peers)
        delta = {"view": params["view"], "insertions": params["insertions"], "deletions": params["deletions"]}

        result = dejimautils.prop_request(target_peers, updated_dt, delta, current_xid, config.peer_name, config.dejima_config_dict)
        
        if result == "Ack":
            resp.body = "true"
        else:
            resp.body = "false"
        print(datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))), " execution finished")
        return