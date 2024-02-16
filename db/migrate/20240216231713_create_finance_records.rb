class CreateFinanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :finance_records do |t|
      t.string :transaction_id
      t.decimal :amount
      t.date :date
      t.text :description

      t.timestamps
    end
  end
end
