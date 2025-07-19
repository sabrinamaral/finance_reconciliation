class AddUserToFinanceRecord2s < ActiveRecord::Migration[7.1]
  def change
    add_reference :finance_record2s, :user, null: false, foreign_key: true
  end
end
