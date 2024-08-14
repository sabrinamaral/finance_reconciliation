class CreateCashFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :cash_flows do |t|
      t.date :date
      t.string :description
      t.decimal :amount
      t.integer :type

      t.timestamps
    end
  end
end
