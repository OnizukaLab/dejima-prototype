module DejimaUtils
    
    def self.create_peer_groups(*models)
        Rails.logger.info(__method__.to_s + " is called")

        # when creating we begin with all locally known peer groups
        peer_groups = self.check_local_peer_groups(models)
        Rails.logger.info "Peers groups: #{peer_groups}"
        self.detect_peer_groups(peer_groups)
    end

    # tries to detect other peer groups in the network based on the locally known peer groups
    def self.detect_peer_groups(peer_groups)
        Rails.logger.info(__method__.to_s + " is called")

        # now we start the network traversal
        peer_groups.each do |dejima_tables, values|
            # create arrays from sets for json serialization
            payload = {}
            payload[:dejima_tables] = dejima_tables.to_a
            payload[:attributes] = values[:attributes].to_a
            payload[:peers] = values[:peers].to_a
            visit_next = values[:peers].subtract(values[:visited]).to_a
            responses = DejimaProxy.send_peer_group_request(visit_next, payload)
            # responses example
            # {"dejima-peer1.dejima-net"=>
            #    [{"dejima_tables"=>["ShareWithInsurance", "ShareWithBank"], "attributes"=>["first_name", "last_name", "address"], "peers"=>["dejima-peer3.dejima-net", "dejima-peer2.dejima-net"]},
            #     {"dejima_tables"=>["ShareWithInsurance"], "attributes"=>["birthdate"], "peers"=>["dejima-peer3.dejima-net"]},
            #     {"dejima_tables"=>["ShareWithBank"], "attributes"=>["phone"], "peers"=>["dejima-peer2.dejima-net"]}]}
              
            responses.each do |peer, response|
                peer_groups[dejima_tables][:visited] << peer
                next if response == "ok" || response == "connection_error"
                # response contains all the entries that signal peer_group_updates
                # Here, processing is performed when it is determined by the detect that the update processing is necessary.
                response.each do |peer_group_update|
                    # TODO:
                end
            end
            # TODO:
            # break loop and restart detection if peer_groups keys (the combination of dejima groups) changed
            # otherwise traverse previously unknown peers
        end
        # TODO:
        # if break
        #self.detect_peer_groups(peer_groups)
        # else broadcast new peer groups
        #self.broadcast_peer_groups
    end

    # used to broadcast updated peer_groups to the whole network
    def self.broadcast_peer_groups(peer_groups)
        # TODO:
        # broadcast...
    end

    # return peer groups by given models (user e.g. GovernmentUser])
    def self.check_local_peer_groups(models)
        Rails.logger.info(__method__.to_s + " is called")

        attribute_to_tables = {}
        tables_to_peers = {}
        models.each do |model|
            # model.dejima_table example:
            # [{:table=>ShareWithInsurance, :peers=>#<Set: {"dejima-peer1.dejima-net", "dejima-peer3.dejima-net"}>}, 
            # {:table=>ShareWithBank, :peers=>#<Set: {"dejima-peer1.dejima-net", "dejima-peer2.dejima-net"}>}]
            model.dejima_tables.each do |dejima_table|
                dejima_table[:table].dejima_attributes.each do |attribute|
                    attribute_to_tables[[model, attribute]] = Set.new unless attribute_to_tables[[model, attribute]]
                    attribute_to_tables[[model, attribute]] << dejima_table[:table]
                    tables_to_peers[dejima_table[:table]] = Set.new unless tables_to_peers[dejima_table]
                    tables_to_peers[dejima_table[:table]] = tables_to_peers[dejima_table[:table]].union dejima_table[:peers]
                end
            end  
        end

        # attribute_to_tables_map example:
        # { 
        #   first_name: [ShareWithInsurance, ShareWithBank],
        #   last_name: [ShareWithInsurance, ShareWithBank],
        #   address: [ShareWithInsurance, ShareWithBank],
        #   phone: [ShareWithBank],
        #   birthdate: [ShareWithInsurance]
        # }

        # tables_to_peers example:
        # {ShareWithBank => {"dejima-bank-peer.dejima-net", "dejima-gov-peer.dejima-net"}}
        peer_groups = {}
        attribute_to_tables.each_pair do |attribute, tables|
            peer_groups[tables] = { attributes: Set.new, peers: Set.new } unless peer_groups[tables]
            peer_groups[tables][:attributes] << attribute[1]
            tables.each do |table|
                peer_groups[tables][:peers] = peer_groups[tables][:peers].union tables_to_peers[table]
            end
            peer_groups[tables][:visited] = Set.new([Rails.application.config.peer_network_address])
        end

        # example of peer_groups
        # {
        # ShareWithBank =>
        #   :attributes => {:first_name, :last_name, :phone, : address},
        #   :peers => {"dejima-bank-peer.dejima-net", "dejima-gov-peer.dejima-net"},
        #   :visited => {"dejima-bank-peer.dejima-net"}
        # }
        peer_groups
    end

    # TODO hardcode for now
    def self.identify_bases(values)
        if Rails.application.config.dejima_peer_type == :government
            return [GovernmentUser]
        elsif Rails.application.config.dejima_peer_type == :bank
            return [BankUser]
        elsif Rails.application.config.dejima_peer_type == :insurance
            return [InsuranceUser]
        else
            []
        end
    end

    def self.format_payload(tables, attributes, peers)

    end

    def self.exec_select(sql)
        Rails.logger.info("\e31m" + __method__.to_s + " is called\e[0m")

        con = ActiveRecord::Base.connection
        return con.select_all(sql).to_hash
    end

    def self.exec_upsert(sql)
        Rails.logger.info("\e31m" + __method__.to_s + " is called\e[0m")

        con = ActiveRecord::Base.connection
        return con.execute(sql).cmd_status()
    end

    def self.exec_query(sql)
        sql = sql.strip.to_s
        sem = Semaphore.new
        sem.acquire()
        begin
            if sql.downcase.to_s.start_with?("insert") or sql.downcase.to_s.start_with?("update") then
                return exec_upsert(sql)
            elsif sql.downcase.to_s.start_with?("select") then
                return exec_select(sql)
            else
                raise "unsupported query type"
            end
        rescue => e
            Rails.logger.error(e.message)
        ensure
            sem.release()
        end
    end

end
