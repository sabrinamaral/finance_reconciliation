class AddReconciledToFinanceRecords < ActiveRecord::Migration[6.0]
  def change
    add_column :finance_records, :reconciled, :boolean, default: false
    add_column :finance_record2s, :reconciled, :boolean, default: false
  end
end
