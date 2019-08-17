require 'yaml'

Rails.application.config.after_initialize do
  if defined?(::Rails::Server) && !Rails.env.to_s.match(/test/)
    Rails.logger.info "Running as dejima peer type: #{Rails.application.config.dejima_peer_type}"

    config = YAML.load_file(ENV['CONFIG'])
    config["peer_types"][Rails.application.config.dejima_peer_type.to_s]["base_table"].keys.each do |base_table|
      DejimaUtils.create_peer_groups(base_table.constantize.table_name)
    end
  end
end
