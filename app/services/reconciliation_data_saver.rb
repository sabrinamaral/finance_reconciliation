class ReconciliationDataSaver
  include FileParser

  class ImportError < StandardError; end

  def initialize(file1, file2, model1, model2, period)
    @file1   = file1
    @file2   = file2
    @model1  = model1
    @model2  = model2
    @period  = period
    @user    = Current.user
  end

  def call
    ActiveRecord::Base.transaction do
      process_file(@file1, @model1)
      process_file(@file2, @model2)
    end
    { success: true }
  rescue ImportError, FileParser::Error => e
    Rails.logger.error "Import failed: #{e.message}"
    { success: false, error: e.message }
  rescue => e
    Rails.logger.error "Transaction failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end

  private

  def process_file(file, model)
    rows = parse_file(file)
    date_order = DateParser.detect_order(rows.map { |row| row.fields[0] })
    raise ImportError, DateParser::CONFLICT_ERROR if date_order == :conflict

    rows.each_with_index do |row, index|
      result = CsvImporter.parse_row(row, date_order: date_order)
      # +1 for zero-based index, +1 for the header row
      raise ImportError, "#{result.error} (row #{index + 2})" unless result.success

      record = model.new(result.data.merge(audit_period: @period, user: @user))
      raise ImportError, "Failed to save record: #{record.errors.full_messages.join(', ')}" unless record.save
    end
  end
end
