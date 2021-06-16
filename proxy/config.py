# peer_name : peer's name
# tx_management_dict : dictionary object for managing transaction
# e.g. {"xid": {"db_conn": db_conn, "lock_peer_list": lock_peer_list, "child_peer_list": child_peer_list}, ...}
# dejima_config_dict : dictionary object for describing peer's configuration
# connection_pool : connection pool for postgreSQL with psycopg2

import os
import json
import psycopg2.pool
from psycopg2 import extensions as _ext
import sys
sys.dont_write_bytecode = True

peer_name = os.environ['PEER_NAME']
tx_management_dict = {}
with open('dejima_config.json') as f:
    dejima_config_dict = json.load(f)

class CustomedAbstractConnectionPool(psycopg2.pool.AbstractConnectionPool):
    def __init__(self, max_txn_cnt, minconn, maxconn, *args, **kwargs):
        self.txn_cnt = {}
        self.max_txn_cnt = max_txn_cnt
        super().__init__(minconn, maxconn, *args, **kwargs)
    def _connect(self, key=None):
        """Create a new connection and assign it to 'key' if not None."""
        conn = psycopg2.connect(*self._args, **self._kwargs)
        self.txn_cnt[id(conn)] = 0
        if key is not None:
            self._used[key] = conn
            self._rused[id(conn)] = key
        else:
            self._pool.append(conn)
        return conn
    def _putconn(self, conn, key=None, close=False):
        self.txn_cnt[id(conn)] += 1
        """Put away a connection."""
        if self.closed:
            raise PoolError("connection pool is closed")

        if key is None:
            key = self._rused.get(id(conn))
            if key is None:
                raise PoolError("trying to put unkeyed connection")

        if len(self._pool) < self.minconn and not close:
            # Return the connection into a consistent state before putting
            # it back into the pool
            if not conn.closed:
                status = conn.info.transaction_status
                if status == _ext.TRANSACTION_STATUS_UNKNOWN or self.txn_cnt[id(conn)] > self.max_txn_cnt:
                    # server connection lost
                    conn.close()
                    del self.txn_cnt[id(conn)]
                elif status != _ext.TRANSACTION_STATUS_IDLE:
                    # connection in error or in transaction
                    conn.rollback()
                    self._pool.append(conn)
                else:
                    # regular idle connection
                    self._pool.append(conn)
            # If the connection is closed, we just discard it.
        else:
            conn.close()
            del self.txn_cnt[id(conn)]

        # here we check for the presence of key because it can happen that a
        # thread tries to put back a connection after a call to close
        if not self.closed or key in self._used:
            del self._used[key]
            del self._rused[id(conn)]

class CustomedThreadedConnectionPool(CustomedAbstractConnectionPool):
    """A connection pool that works with the threading module."""

    def __init__(self, max_txn_cnt, minconn, maxconn, *args, **kwargs):
        """Initialize the threading lock."""
        import threading
        CustomedAbstractConnectionPool.__init__(
            self, max_txn_cnt, minconn, maxconn, *args, **kwargs)
        self._lock = threading.Lock()

    def getconn(self, key=None):
        """Get a free connection and assign it to 'key' if not None."""
        self._lock.acquire()
        try:
            return self._getconn(key)
        finally:
            self._lock.release()

    def putconn(self, conn=None, key=None, close=False):
        """Put away an unused connection."""
        self._lock.acquire()
        try:
            self._putconn(conn, key, close)
        finally:
            self._lock.release()

    def closeall(self):
        """Close all connections (even the one currently in use.)"""
        self._lock.acquire()
        try:
            self._closeall()
        finally:
            self._lock.release()

while True:
    try: 
        connection_pool = CustomedThreadedConnectionPool(max_txn_cnt=30, minconn=3, maxconn=3, host="{}-db".format(peer_name), port="5432", dbname="postgres", user="dejima", password="barfoo")
        break
    except Exception:
        pass