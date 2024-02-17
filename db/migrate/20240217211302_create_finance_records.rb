class CreateFinanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :finance_records do |t|
      t.date :date
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
