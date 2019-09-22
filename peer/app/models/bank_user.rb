require 'set'

class BankUser < ApplicationRecord
  include DejimaBase
  # table columns
  # id, first_name, last_name, phone, iban
end
