class CashFlow < ApplicationRecord
  require 'csv'

  def self.import_from_csv(file)
    CSV.foreach(file.path, headers: true) do |row|
      cash_flow_attributes = row.to_hash.transform_keys(&:underscore)
      CashFlow.create!(cash_flow_attributes )
    end
  end

end
