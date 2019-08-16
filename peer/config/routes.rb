Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get 'hello', to: 'application#hello', controller: 'application'

  scope :dejima do
    post 'detect', to: 'dejima#detect', controller: 'dejima'
    post 'propagate', to: 'dejima#propagate', controller: 'dejima'
    post 'update_dejima_table', to: 'dejima#update_dejima_table', controller: 'dejima'
  end
end
