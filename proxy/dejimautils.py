import json
import sqlparse
from sqlparse.sql import IdentifierList, Identifier
from sqlparse.tokens import Keyword, DML
import threading
import requests

def lock_request_with_lineage(peers, lineages, current_xid, dejima_config_dict):
    thread_list = []
    results = []
    for peer in peers:
        url = "http://{}/_lock".format(dejima_config_dict['peer_address'][peer])
        data = {
            "xid": current_xid,
            "lineages": lineages
        }
        thread = threading.Thread(target=base_request, args=([url, data, results]))
        thread_list.append(thread)
    
    for thread in thread_list:
        thread.start()
    
    for thread in thread_list:
        thread.join()
    
    if all(results):
        return "Ack"
    else:
        return "Nak"

def prop_request(peers, dt, delta, inserted_lineages, deleted_lineages, current_xid, dejima_config_dict):
    thread_list = []
    results = []
    for peer in peers:
        data = {
            "xid": current_xid,
            "dejima_table": dt,
            "delta": delta,
            "inserted_lineages": inserted_lineages,
            "deleted_lineages": deleted_lineages
        }
        url = "http://{}/_propagate".format(dejima_config_dict['peer_address'][peer])
        thread = threading.Thread(target=base_request, args=([url, data, results]))
        thread_list.append(thread)
    
    for thread in thread_list:
        thread.start()
    
    for thread in thread_list:
        thread.join()
    
    if all(results):
        return "Ack"
    else:
        return "Nak"

def termination_request(peers, result, current_xid, dejima_config_dict):
    thread_list = []
    results = []
    for peer in peers:
        data = {
            "xid": current_xid,
            "result": result
        }
        url = "http://{}/_terminate".format(dejima_config_dict['peer_address'][peer])
        thread = threading.Thread(target=base_request, args=([url, data, results]))
        thread_list.append(thread)
    
    for thread in thread_list:
        thread.start()
    
    for thread in thread_list:
        thread.join()
    
    if all(results):
        return "Ack"
    else:
        return "Nak"

def base_request(url, data, results):
    try:
        headers = {"Content-Type": "application/json"}
        res = requests.post(url, json.dumps(data), headers=headers)
        if res.json()['result'] == "Ack":
            results.append(True)
        else:
            results.append(False)
    except Exception as e:
        print(e)
        results.append(False)

def convert_to_sql_from_json(json_data):
    # arg : json_data from other peer
    # output : view name(str) , sql statements for view(str)
    sql_statements = []
    json_dict = json.loads(json_data)

    for delete in json_dict["deletions"]:
        where = ""
        for column, value in delete.items():
            if not value and value != 0:
                continue
            if type(value) is str:
                value=value.strip() # Note: value contains strange Tabs
                where += "{}='{}' AND ".format(column, value)
            else:
                where += "{}={} AND ".format(column, value)
        where = where[0:-4]
        sql_statements.append("DELETE FROM {} WHERE {};".format(json_dict["view"], where))

    for insert in json_dict["insertions"]:
        columns = "("
        values = "("
        for column, value in insert.items():
            columns += "{}, ".format(column)
            if not value and value != 0:
                values += "NULL, "
            elif type(value) is str:
                value=value.strip() # Note: value contains strange Tabs
                values += "'{}', ".format(value)
            else:
                values += "{}, ".format(value)
        columns = columns[0:-2] + ")"
        values = values[0:-2] + ")"
        sql_statements.append("INSERT INTO {} {} VALUES {};".format(json_dict["view"], columns, values))

    return json_dict["view"].split(".")[1], sql_statements

# ----- get table names -----
def is_subselect(parsed):
    if not parsed.is_group:
        return False
    for item in parsed.tokens:
        if item.ttype is DML and item.value.upper() == 'SELECT':
            return True
    return False

def extract_from_part(parsed):
    from_seen = False
    for item in parsed.tokens:
        if from_seen:
            if is_subselect(item):
                yield from extract_from_part(item)
            elif item.ttype is Keyword:
                return
            else:
                yield item
        elif item.ttype is Keyword and item.value.upper() == 'FROM':
            from_seen = True

def extract_table_identifiers(token_stream):
    for item in token_stream:
        if isinstance(item, IdentifierList):
            for identifier in item.get_identifiers():
                yield identifier.get_name()
        elif isinstance(item, Identifier):
            yield item.get_name()
        # It's a bug to check for Keyword here, but in the example
        # above some tables names are identified as keywords...
        elif item.ttype is Keyword:
            yield item.value

def extract_tables(sql):
    stream = extract_from_part(sqlparse.parse(sql)[0])
    return list(extract_table_identifiers(stream))