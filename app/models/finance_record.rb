class FinanceRecord < ApplicationRecord
  validates :date, :amount, presence: true
end
