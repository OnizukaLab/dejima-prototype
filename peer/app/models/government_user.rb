require 'set'

class GovernmentUser < ApplicationRecord
  include DejimaBase
  # table columns
  # id, first_name, last_name, phone, address, birthdate
end
