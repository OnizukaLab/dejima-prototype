module DejimaUtils
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
