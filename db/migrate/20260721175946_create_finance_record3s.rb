class CreateFinanceRecord3s < ActiveRecord::Migration[8.1]
  def change
    create_table :finance_record3s do |t|
      t.date :date
      t.text :description
      t.decimal :amount
      t.boolean :reconciled, default: false
      t.boolean :checked, default:false
      t.references :audit_period, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
