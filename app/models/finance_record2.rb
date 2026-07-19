class FinanceRecord2 < ApplicationRecord
  belongs_to :user
  belongs_to :audit_period, optional: true  # optional during migration period

  scope :for_current_user, -> { where(user_id: Current.user.id) if Current.user }

  validates :date, presence: true
  validates :amount, presence: true, numericality: true
end
