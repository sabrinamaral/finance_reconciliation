class RenameTypeColumnInCashFlows < ActiveRecord::Migration[7.1]
  def change
    rename_column :cash_flows, :type, :transaction_type
  end
end
