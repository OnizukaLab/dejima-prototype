class DejimaController < ApplicationController

  def create_user
    first_name = params["first_name"] || "John"
    last_name = params["last_name"] || "Doe"
    BankUser.create(first_name: first_name, last_name: last_name)
  end

  def exec_sql
    sql = params[:sql]
    Rails.logger.info("\e[31m " + sql + " is called\e[0m")
    render json: JSON.generate(DejimaUtils.exec_query(sql))
  end
end
