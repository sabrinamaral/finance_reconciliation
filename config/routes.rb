Rails.application.routes.draw do
  root 'finance_records#new'

  get 'finance_records/show'
  post 'finance_records', to: 'finance_records#create'
  delete 'finance_records', to: 'finance_records#delete_all'

  get "password", to: "passwords#edit", as: :edit_password
  patch "password", to: "passwords#update"

  get "password/reset", to: "password_resets#new"
  post "password/reset", to: "password_resets#create"

  get "sign_up", to: "users#new"
  post "sign_up", to: "users#create"

  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

end
