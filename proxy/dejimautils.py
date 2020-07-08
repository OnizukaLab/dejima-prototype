import json

def convert_to_sql_from_json(json_data):
    # arg : json_data from other peer
    # output : view name(str) , sql statements for view(str)
    sql_statements = []
    json_dict = json.loads(json_data)
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

    for delete in json_dict["deletions"]:
        where = ""
        for column, value in delete.items():
            if not value and value != 0:
                continue
            where += "{}='{}' AND ".format(column, value)
        where = where[0:-4]
        sql_statements.append("DELETE FROM {} WHERE {};".format(json_dict["view"], where))

    return json_dict["view"], sql_statements