Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
  as :user do
    get   "users/edit", to: "devise/registrations#edit",   as: :edit_user_registration
    patch "users",      to: "devise/registrations#update", as: :user_registration
    put   "users",      to: "devise/registrations#update"
  end

  root 'reconciliations#index'

  resources :cash_flows, only: [:create, :index, :update, :destroy] do
    collection do
      post "add_transaction"
      delete 'delete_all'
    end
  end

  post "set_balance", to: "cash_flows#set_balance"
  post "reset_balance", to: "cash_flows#reset_balance"

  resources :audits, only: [] do
    resources :audit_periods, only: [:create], shallow: true
  end

  resources :reconciliations, only: [:create, :index] do
    collection do
      delete :delete_all
      get    :download_pdf
      get    :download_excel
      get    :audit
      patch  :toggle_checked
      patch  :bulk_check
    end
  end

  resources :receipt_reconciliations, only: [:index, :create] do
    collection do
      delete :delete_all
      get    :download_pdf
      get    :download_excel
      patch  :toggle_checked
      patch  :bulk_check
    end
  end

  resources :invoice_reconciliations, only: [:index, :create] do
    collection do
      delete :delete_all
      get    :download_pdf
      get    :download_excel
      patch  :toggle_checked
      patch  :bulk_check
    end
  end
end
