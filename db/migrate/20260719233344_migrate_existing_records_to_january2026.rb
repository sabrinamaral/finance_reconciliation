class MigrateExistingRecordsToJanuary2026 < ActiveRecord::Migration[8.1]
  def up
    # Find all users that have existing finance records
    user_ids = FinanceRecord.distinct.pluck(:user_id) |
              FinanceRecord2.distinct.pluck(:user_id)

    user_ids.each do |user_id|
      # Create a default audit for this user
      audit = Audit.create!(
        name: "Auditoria Principal",
        user_id: user_id
      )

      # Create the January 2026 period
      period = AuditPeriod.create!(
        audit: audit,
        month: 1,
        year: 2026
      )

      # Associate all existing records to this period
      FinanceRecord.where(user_id: user_id).update_all(audit_period_id: period.id)
      FinanceRecord2.where(user_id: user_id).update_all(audit_period_id: period.id)
    end
  end

  def down
    # Reversible: clears the associations and removes audits/periods created here
    FinanceRecord.update_all(audit_period_id: nil)
    FinanceRecord2.update_all(audit_period_id: nil)
    AuditPeriod.delete_all
    Audit.delete_all
  end
end
