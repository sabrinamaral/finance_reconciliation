# app/models/audit.rb
class Audit < ApplicationRecord
  belongs_to :user
  has_many :audit_periods, dependent: :destroy

  validates :name, presence: true
end
