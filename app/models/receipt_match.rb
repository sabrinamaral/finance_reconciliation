class ReceiptMatch < ApplicationRecord
  belongs_to :finance_record
  belongs_to :finance_record3, optional: true
end
