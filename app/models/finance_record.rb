class FinanceRecord < ApplicationRecord
# validates :date, :amount, presence: true

# # Validate the format of the date (DD/MM/YYYY)
# validates :date, format: { with: /\A\d{2}\/\d{2}\/\d{4}\z/, message: "must be in the format DD/MM/YYYY" }

# # Validate the format of the amount (e.g., 1.000,00)
# validates :amount, format: { with: /\A\d{1,3}(\.\d{3})*,\d{2}\z/, message: "must be in the format 1.000,00" }

end
