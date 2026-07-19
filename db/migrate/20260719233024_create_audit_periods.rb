class CreateAuditPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_periods do |t|
      t.references :audit, null: false, foreign_key: true
      t.integer :month
      t.integer :year

      t.timestamps
    end
  end
end
