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
  rescue ImportError => e
    Rails.logger.error "Import failed: #{e.message}"
    { success: false, error: e.message }
  rescue => e
    Rails.logger.error "Transaction failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end

  private

  def process_file(file, model)
    parse_file(file).each_with_index do |row, index|
      result = CsvImporter.parse_row(row)
      raise ImportError, "#{result.error} (row #{index + 1})" unless result.success

      record = model.new(result.data.merge(audit_period: @period, user: @user))
      raise ImportError, "Failed to save record: #{record.errors.full_messages.join(', ')}" unless record.save
    end
  rescue CSV::MalformedCSVError => e
    raise ImportError, "Malformed CSV file: #{e.message}"
  end
end
