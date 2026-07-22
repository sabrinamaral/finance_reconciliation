class CreateReceiptMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_matches do |t|
      t.references :finance_record, null: false, foreign_key: true, index: { unique: true }
      t.references :finance_record3, foreign_key: true

      t.boolean :checked, default: false
      t.boolean :reconciled, default: false

      t.timestamps
    end
  end
end
