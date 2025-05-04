class FinanceRecord2 < ApplicationRecord
  validates :date, presence: true
  validates :amount, presence: true, numericality: true
end
