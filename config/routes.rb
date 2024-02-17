Rails.application.routes.draw do
  root 'finance_records#new'
  get 'finance_records/show'
  post 'finance_records', to: 'finance_records#create'
  delete 'finance_records', to: 'finance_records#delete_all'
end
