# tx_management_dict : dictionary object for managing transaction
# e.g. {"xid": {"db_conn": db_conn, "lock_peer_list": lock_peer_list, "child_peer_list": child_peer_list}, ...}
import dejimautils

class Transaction():
    def __init__(self, xid):
        self.xid = xid
    
    def propagate(self, target_dt):
        pass
    
    def terminate(self):
        pass