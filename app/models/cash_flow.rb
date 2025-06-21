class CashFlow < ApplicationRecord
  require 'csv'
  EXPECTED_HEADERS = %w[date description amount transaction_type].freeze

  validates :date, presence: true
  validates :description, presence: true
  validates :amount, presence: true, numericality: true
  validates :transaction_type, presence: true


  def self.import_from_csv(file)
    headers = nil
    CSV.foreach(file, headers: true) do |row|
      if headers.nil?
        headers = row.headers.map(&:strip).map(&:underscore)
        unless headers_match?(headers)
          return { success: false, error: "CSV headers must be: #{EXPECTED_HEADERS.join(', ')}" }
        end
      end
      cash_flow_attributes = row.to_hash.transform_keys(&:underscore)
      cash_flow_attributes['amount'] = cash_flow_attributes['amount']&.gsub(/[[:space:]]/, '')&.tr('R$', '')
      cash_flow_attributes['amount'] = cash_flow_attributes['amount'].gsub('.', '')&.gsub(',', '.').to_f
      CashFlow.create!(cash_flow_attributes)
    end
    { success: true }
  end

  def self.headers_match?(headers)
    headers.sort == EXPECTED_HEADERS.sort
  end
end
