class AddAuditPeriodToFinanceRecords < ActiveRecord::Migration[8.1]
  def change
    add_reference :finance_records, :audit_period, null: true, foreign_key: true
  end
end
