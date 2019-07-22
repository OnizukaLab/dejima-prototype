module DejimaTable
  extend ActiveSupport::Concern

  included do
    dejima_attributes
  end

  class_methods do
    attr_accessor :dejima_attributes

    def define_attribute(*attrs)
      self.dejima_attributes = attrs
      Rails.logger.info "Defined dejima attributes on #{self} => #{attrs}"
    end
  end
end
