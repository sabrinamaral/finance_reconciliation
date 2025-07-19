class FinanceRecord < ApplicationRecord
  belongs_to :user
  scope :for_current_user, -> { where(user_id: Current.user.id) if Current.user }

  validates :date, presence: true
  validates :amount, presence: true, numericality: true
end
