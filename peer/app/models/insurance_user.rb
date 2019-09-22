require 'set'

class InsuranceUser < ApplicationRecord
  include DejimaBase
  # table columns
  # id, first_name, last_name, address, birthdate, insurance_number
end
