Rails.application.routes.draw do
  root 'reconciliations#index'

  resources :cash_flows, only: [:create, :index, :update, :destroy]
  resources :reconciliations, only: [:new, :create, :index]

  resources :reconciliations do
    collection do
      delete 'delete_all'
    end
  end

  get "password", to: "passwords#edit", as: :edit_password
  patch "password", to: "passwords#update"

  get "password/reset", to: "password_resets#new"
  post "password/reset", to: "password_resets#create"
  get "password/reset/edit", to: "password_resets#edit"
  patch "password/reset/edit", to: "password_resets#update"

  get "sign_up", to: "users#new"
  post "sign_up", to: "users#create"

  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

end
