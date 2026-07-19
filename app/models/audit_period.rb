# app/models/audit_period.rb
class AuditPeriod < ApplicationRecord
  belongs_to :audit
  has_many :finance_records, dependent: :destroy
  has_many :finance_record2s, dependent: :destroy

  validates :month, presence: true,
                    numericality: { only_integer: true, in: 1..12 }
  validates :year,  presence: true,
                    numericality: { only_integer: true, greater_than: 2000 }
  validates :month, uniqueness: { scope: [:audit_id, :year],
                    message: "already exists for this audit and year" }

  def label
    Date.new(year, month, 1).strftime("%B/%Y")
  end
end
