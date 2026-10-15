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
    rows = parse_file(@file)
    date_order = DateParser.detect_order(rows.map { |row| row.fields[0] })
    raise ImportError, DateParser::CONFLICT_ERROR if date_order == :conflict

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        result = CsvImporter.parse_row(row, date_order: date_order)
        # +1 for zero-based index, +1 for the header row
        raise ImportError, "#{result.error} (row #{index + 2})" unless result.success

        record = @model.new(result.data.merge(audit_period: @period, user: @user))
        raise ImportError, "Failed to save record: #{record.errors.full_messages.join(', ')}" unless record.save
      end
    end
    { success: true }
  rescue ImportError, FileParser::Error => e
    {success: false, error: e.message}
  rescue => e
    Rails.logger.error "ReceiptDataSaver failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end
end
