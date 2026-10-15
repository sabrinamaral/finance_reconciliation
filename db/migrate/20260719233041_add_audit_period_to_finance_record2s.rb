class AddAuditPeriodToFinanceRecord2s < ActiveRecord::Migration[8.1]
  def change
    add_reference :finance_record2s, :audit_period, null: true, foreign_key: true
  end
end
