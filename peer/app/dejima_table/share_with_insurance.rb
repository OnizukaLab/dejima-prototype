class ShareWithInsurance < DejimaTable

  self.view_name = 'dejima_insurance'
  define_attribute  :first_name,
                    :last_name,
                    :address,
                    :birthdate
end
