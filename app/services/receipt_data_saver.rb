class ReceiptDataSaver
  include FileParser

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

        unless result.success
          return { success: false, error: "#{result.error} (row #{index + 1})" }
        end

        record = @model.new(result.data.merge(audit_period: @period, user: @user))

        unless record.save
          return { success: false, error: "Failed to save record: #{record.errors.full_messages.join(', ')}" }
        end
      end
    end
    { success: true }
  rescue => e
    Rails.logger.error "ReceiptDataSaver failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end
end
