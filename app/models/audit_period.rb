# app/models/audit_period.rb
class AuditPeriod < ApplicationRecord
  belongs_to :audit
  has_many :finance_records, dependent: :destroy
  has_many :finance_record2s, dependent: :destroy
  has_many :finance_record3s, dependent: :destroy
  has_many :finance_record4s, dependent: :destroy

  validates :month, presence: true,
                    numericality: { only_integer: true, in: 1..12 }
  validates :year,  presence: true,
                    numericality: { only_integer: true, greater_than: 2000 }
  validates :month, uniqueness: { scope: [:audit_id, :year],
                    message: "already exists for this audit and year" }

  # Deletes the period and everything imported into it, in foreign key order:
  # matches first, then the records they point to, then the period itself.
  def destroy_with_records!
    transaction do
      bank_ids    = FinanceRecord.where(audit_period: self).select(:id)
      receipt_ids = FinanceRecord3.where(audit_period: self).select(:id)
      invoice_ids = FinanceRecord4.where(audit_period: self).select(:id)

      ReceiptMatch.where(finance_record_id: bank_ids)
                  .or(ReceiptMatch.where(finance_record3_id: receipt_ids))
                  .delete_all
      InvoiceMatch.where(finance_record_id: bank_ids)
                  .or(InvoiceMatch.where(finance_record4_id: invoice_ids))
                  .delete_all

      [FinanceRecord, FinanceRecord2, FinanceRecord3, FinanceRecord4].each do |model|
        model.where(audit_period: self).delete_all
      end

      destroy!
    end
  end


  def label
    Date.new(year, month, 1).strftime("%B/%Y")
  end
end
