class ShareWithBank < DejimaTable

  self.view_name = 'dejima_bank'
  define_attribute  :first_name,
                    :last_name,
                    :phone,
                    :address
end
