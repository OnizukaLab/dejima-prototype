class DejimaTable
  include DejimaTableModule

  class_attribute :view_name

  def self.get_dejima_table_by_view(view_name)
    self.descendants.select do |dejima_table|
      dejima_table.view_name == view_name
    end.to_set
  end
end
