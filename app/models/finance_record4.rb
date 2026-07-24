# app/models/finance_record4.rb
class FinanceRecord4 < ApplicationRecord
  belongs_to :user
  belongs_to :audit_period
  has_one :invoice_match, dependent: :nullify

  scope :for_current_user, -> { where(user_id: Current.user.id) if Current.user }

  validates :date, presence: true
  validates :amount, presence: true, numericality: true
end
