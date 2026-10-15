# app/models/invoice_match.rb
class InvoiceMatch < ApplicationRecord
  belongs_to :finance_record
  belongs_to :finance_record4, optional: true
end
