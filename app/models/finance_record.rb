class FinanceRecord < ApplicationRecord
  validates :date, presence: true
  validates :amount, presence: true, numericality: true
end
