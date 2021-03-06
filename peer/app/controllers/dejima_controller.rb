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
    # it probably would not work in multi-worker mode as it's not shared across processes,
    # but it illustrates the concept
    @mutex.synchronize do
      Rails.logger.info "Responding to detection request"
      remote_peer_groups = JSON.parse(params["peer_groups"], symbolize_names: true).map(&PeerGroup.method(:new))
      render json: DejimaUtils.compare_remote_peer_groups(remote_peer_groups)
    end
  end

  # update config based on newer detection run of a peer
  # only available for config.prototype_role == :peer
  def update_peers; end

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

    sql_statements_insertions = []
    sql_statements_deletions= []
    params["insertions"].each do |insert|
      sql_columns = "("
      sql_values = "("
      insert.each do |column, value|
        sql_columns += "#{column}, "
        sql_values += if value.nil?
                        "NULL, "
                      else
                        "'#{value}', "
                      end
      end
      sql_columns = sql_columns[0..-3] + ")"
      sql_values = sql_values[0..-3] + ")"
      sql_statements_insertions << "INSERT INTO #{params['view']} #{sql_columns} VALUES #{sql_values};"
    end
    params["deletions"].each do |delete|
      sql_where = ""
      delete.each do |column, value|
        sql_where += "#{column}="
        sql_where += if value.nil?
                        "NULL, "
                      else
                        "'#{value}' AND "
                      end
      end
      sql_where = sql_where[0..-5] 
      sql_statements_deletions << "DELETE FROM #{params['view']} WHERE #{sql_where};" 
    end
    Rails.logger.info("Updating dejima table #{params['view']} with statements:\n#{sql_statements_insertions.join("\n")}")
    Rails.logger.info("Updating dejima table #{params['view']} with statements:\n#{sql_statements_deletions.join("\n")}")
    if params["insertions"] != [] 
      ActiveRecord::Base.connection.execute(sql_statements_insertions.join("\n"))
    end
    if params["deletions"] != []
      ActiveRecord::Base.connection.execute(sql_statements_deletions.join("\n"))
    end
    render json: "true"
  end
end
