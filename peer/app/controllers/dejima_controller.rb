class DejimaController < ApplicationController

  def initialize
    super
    @mutex = Mutex.new
  end

  # respond to peer group detection
  # only available for config.prototype_role == :peer
  def detect
    Rails.logger.info("\e[31m" + __method__.to_s + " is called\e[0m")

    raise "Only peer role can run detection" unless Rails.application.config.prototype_role == :peer

    # needs to be synchronized to avoid race conditions on 
    # multiple peers initilizing at the same time
    # this mutex might be redundant, because we are running in single server mode and 
    # it would not work in multi-worker mode as it's not shared across processes, but
    # it illustrates the concept
    @mutex.synchronize do
      Rails.logger.info "Responding to detection request"
      dejima_tables = Set.new(params["dejima_tables"])
      peers = Set.new(params["peers"])
      bases = DejimaUtils.identify_bases(dejima_tables) # get whoami by config, **param: dejima_tables is not used inside**
      local_peer_groups = DejimaUtils.check_local_peer_groups(bases)
      respond = [] # response is used by rails :)  
      local_peer_groups.each do |tables, values|
        # respond if we found tables that are a proper superset (not euqal) or if we know peers not yet known
        # in the first case the requesting peer needs to be informed about another dejima group needing this data
        # in the second case there exist more peers needing the data than the requester knew about
        if tables.proper_superset?(dejima_tables) || !values[:peers].subtract(peers).empty?
          payload = {}
          payload[:dejima_tables] = tables.to_a # e.g. ShareWithBank
          payload[:attributes] = values[:attributes].to_a # e.g. first_name, last_name, phone, address
          payload[:peers] = values[:peers].to_a # e.g. dejima-bank-peer.dejima-net, dejima-gov-peer.dejima-net
          respond << payload
        end
      end
      if respond.empty?
        Rails.logger.info "Detected no required updates to request. Ok!"
        render json: JSON.generate("ok")
      else
        Rails.logger.info "Detected necessary updates:\n #{JSON.pretty_generate(respond)}"
        render json: JSON.generate(respond)
      end
    end
  end

  # update config based on newer detection run of a peer
  # only available for config.prototype_role == :peer
  def update_peers

  end

  # only available for config.prototype_role == :peer
  def propagate
    Rails.logger.info("\e[31m" + __method__.to_s + " is called\e[0m")

    params.permit! # permit all, this api endpoint is used by the database
    params_hash = params.to_h
    payload_hash = {}
    # Parameters: {"view"=>"public.dejima_bank", "insertion"=>[{"first_name"=>"John", "last_name"=>"Doe", "phone"=>nil, "address"=>nil}], "deletion"=>[]}
    payload_hash[:view] = params_hash["view"]
    payload_hash[:insertions] = params_hash["insertions"]
    payload_hash[:deletions] = params_hash["deletions"]
    DejimaProxy.send_update_dejima_table(payload_hash)
    render json: "true"
  end

  # only available for config.prototype_role == :peer
  def update_dejima_table
    Rails.logger.info("\e[31m" + __method__.to_s + " is called\e[0m")

    sql_statements = []
    params["insertions"].each do |insert|
      sql_columns = "("
      sql_values = "("
      insert.each do |column, value|
        sql_columns += "#{column}, "
        if value.nil?
          sql_values += "NULL, "
        else
          sql_values += "'#{value}', "
        end
      end
      sql_columns = sql_columns[0..-3] + ")"
      sql_values = sql_values[0..-3] + ")"
      sql_statements << "INSERT INTO #{params["view"]} #{sql_columns} VALUES #{sql_values};"
    end
    Rails.logger.info("Updating dejima table #{params["view"]} with statements:\n#{sql_statements.join("\n")}")
    ActiveRecord::Base.connection.execute(sql_statements.join("\n"))
    render json: "true"
  end

  # only available for config.prototype_role == :client
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
