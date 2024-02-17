class CreateFinanceRecord2s < ActiveRecord::Migration[7.1]
  def change
    create_table :finance_record2s do |t|
      t.date :date
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
