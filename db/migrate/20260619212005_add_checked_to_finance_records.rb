class AddCheckedToFinanceRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :finance_records, :checked, :boolean, default: false
    add_column :finance_record2s, :checked, :boolean, default: false
  end
end
