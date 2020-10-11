import json
import sqlparse

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
            where += "{}='{}' AND ".format(column, value)
        where = where[0:-4]
        sql_statements.append("DELETE FROM {} WHERE {};".format(json_dict["view"], where))

    for insert in json_dict["insertions"]:
        columns = "("
        values = "("
        for column, value in insert.items():
            columns += "{}, ".format(column)
            if not value and value != 0:
                values += "NULL, "
            else:
                values += "'{}', ".format(value)
        columns = columns[0:-2] + ")"
        values = values[0:-2] + ")"
        sql_statements.append("INSERT INTO {} {} VALUES {};".format(json_dict["view"], columns, values))

    return json_dict["view"], sql_statements

def convert_to_lock_stmts(sql_stmts):
    ret_stmts = []
    for stmt in sql_stmts:
        stmt = sqlparse.format(stmt, keyword_case="upper")
        if stmt.startswith("SELECT"):
            stmt = stmt + " FOR SHARE"
        elif stmt.startswith("UPDATE"):
            parsed_stmt = sqlparse.parse(stmt)
            where_clause = ""
            for token in parsed_stmt[0]:
                if type(token) == sqlparse.sql.Where: where_clause=token.value; break
            table_name = parsed_stmt[0][2].value if parsed_stmt[0][2].value != "ONLY" else parsed_stmt[0][4].value
            stmt = "SELECT * FROM {} {} FOR UPDATE".format(table_name, where_clause)
        else:
            continue
        ret_stmts.append(stmt)

    return ret_stmts
        
def convert_to_oid_rwset_from_sql(sql_statements):
    for statement in sql_statements:
        if statement.startwith("SELECT"):
            pass
    pass