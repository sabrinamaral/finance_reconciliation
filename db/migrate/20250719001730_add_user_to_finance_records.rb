class AddUserToFinanceRecords < ActiveRecord::Migration[7.1]
  def change
    add_reference :finance_records, :user, null: false, foreign_key: true
  end
end
