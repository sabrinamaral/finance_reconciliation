Rails.application.routes.draw do
  root 'finance_records#new'

  get 'finance_records/show'
  post 'finance_records', to: 'finance_records#create'
  delete 'finance_records', to: 'finance_records#delete_all'

  get "sign_up", to: "users#new"
  post "sign_up", to: "users#create"

  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

end
