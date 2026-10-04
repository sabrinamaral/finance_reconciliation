class ReceiptDataSaver
  include FileParser
  class ImportError < StandardError; end

  def initialize(file, model, period)
    @file   = file
    @model  = model
    @period = period
    @user   = Current.user
  end

  def call
    ActiveRecord::Base.transaction do
      parse_file(@file).each_with_index do |row, index|
        result = CsvImporter.parse_row(row)
        raise ImportError, "#{result.error} (row #{index + 1})" unless result.success

        record = @model.new(result.data.merge(audit_period: @period, user: @user))
        raise ImportError, "Failed to save record: #{record.errors.full_messages.join(', ')}" unless record.save
      end
    end
    { success: true }
  rescue ImportError => e
    {success: false, error: e.message}
  rescue => e
    Rails.logger.error "ReceiptDataSaver failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end
end
