Rails.application.routes.draw do
  root 'finance_records#new'
  post 'finance_records', to: 'finance_records#create'
end
