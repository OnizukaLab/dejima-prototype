Rails.application.routes.draw do

  scope :dejima do
    get 'create_user/:first_name/:last_name', to: 'dejima#create_user', controller: 'dejima'
    get 'exec_sql', to: 'dejima#exec_sql', controller: 'dejima'
  end
end
