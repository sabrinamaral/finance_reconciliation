Rails.application.routes.draw do
  devise_for :users
  root 'reconciliations#index'

  resources :cash_flows, only: [:create, :index, :update, :destroy] do
    collection do
      delete 'delete_all'
    end
  end

  post "set_balance", to: "cash_flows#set_balance"
  post "reset_balance", to: "cash_flows#reset_balance"

  resources :reconciliations, only: [:new, :create, :index] do
    collection do
      delete 'delete_all'
      get 'download_pdf'
    end
  end

end
