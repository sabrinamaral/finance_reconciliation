class User < ApplicationRecord
  has_many :cash_flows, dependent: :destroy
  has_many :finance_records, dependent: :destroy
  has_many :finance_record2s, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
