class DejimaController < ApplicationController

  def create_user
    first_name = params["first_name"] || "John"
    last_name = params["last_name"] || "Doe"
    sql = "INSERT INTO bank_users (first_name, last_name,address, phone) VALUES (\'#{first_name}\', \'#{last_name}\', \'address1\', \'phone1')"
    render json: JSON.generate(DejimaUtils.exec_query(sql))
  end

  def exec_sql
    sql = params[:sql]
    Rails.logger.info("\e[31m " + sql + " is called\e[0m")
    render json: JSON.generate(DejimaUtils.exec_query(sql))
  end
end
