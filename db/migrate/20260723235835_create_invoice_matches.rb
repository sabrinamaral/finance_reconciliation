class CreateInvoiceMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_matches do |t|
      t.references :finance_record, null: false, foreign_key: true, index: { unique: true }
      t.references :finance_record4, foreign_key: true

      t.boolean :checked, default: false
      t.boolean :reconciled, default: false

      t.timestamps
    end
  end
end
