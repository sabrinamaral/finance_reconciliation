class ReconciliationDataSaver
  include FileParser

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
      result1 = process_file(@file1, @model1)
      return result1 unless result1[:success]

      result2 = process_file(@file2, @model2)
      return result2 unless result2[:success]
    end
    { success: true }
  rescue => e
    Rails.logger.error "Transaction failed: #{e.message}"
    { success: false, error: "Transaction failed: #{e.message}" }
  end

  private

  def process_file(file, model)
    Rails.logger.info "Processing file: #{file}"

    begin
      parse_file(file).each_with_index do |row, index|
        result = CsvImporter.parse_row(row)

        unless result.success
          error_msg = "#{result.error} (row #{index + 1})"
          Rails.logger.error error_msg
          return { success: false, error: error_msg }
        end

        record = model.new(result.data.merge(audit_period: @period, user: @user))

        unless record.save
          Rails.logger.error "Failed to save record: #{record.errors.full_messages.join(', ')}"
          return { success: false, error: "Failed to save record: #{record.errors.full_messages.join(', ')}" }
        end

        Rails.logger.info "Record saved successfully: #{record.inspect}"
      end
    rescue CSV::MalformedCSVError => e
      Rails.logger.error "Malformed CSV error: #{e.message}"
      return { success: false, error: "Malformed CSV file: #{e.message}" }
    end
    { success: true }
  end
end
