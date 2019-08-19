require 'yaml'

module DejimaBase
  extend ActiveSupport::Concern

  included do |base|
    self.dejima_tables = nil

    config = YAML.load_file(ENV['CONFIG'])

    views = []
    config["peer_types"][Rails.application.config.dejima_peer_type.to_s]["base_table"][base.to_s]["dejima_table"].each do |dt|
      view = {}
      view[:table] = dt.constantize
      view[:peers] = config["dejima_tables"][dt]["peers"].to_set
      views << view
    end
    base.link_dejima_tables views
  end

  class_methods do
    attr_accessor :dejima_tables

    def link_dejima_tables(views)
      self.dejima_tables = views
      Rails.logger.info "Linked dejima views on #{self} => #{views}"
    end
  end
end
