class FinanceRecord2 < ApplicationRecord
  validates :date, :amount, presence: true
end
