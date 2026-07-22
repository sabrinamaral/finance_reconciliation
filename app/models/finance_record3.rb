class FinanceRecord3 < ApplicationRecord
  belongs_to :audit_period
  belongs_to :user

  has_one :receipt_match, dependent: :nullify
  scope :for_current_user, -> {where(user_id: Current.user.id) if Current.user}

  validates :date, presence: true
  validates :amount, presence: true, numericality:true
end
