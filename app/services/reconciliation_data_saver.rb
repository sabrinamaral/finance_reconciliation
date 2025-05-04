class ReconciliationDataSaver
  def initialize(file1, file2, model1, model2)
    @file1 = file1
    @file2 = file2
    @model1 = model1
    @model2 = model2
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
    { success: false, error: "Transaction failed: #{e.message}"}
  end

  private

  def process_file(file, model)
    Rails.logger.info "Processing file: #{file}"

    begin
      CSV.foreach(file, headers: true).with_index(1) do |row, index|
        Rails.logger.info "Processing row #{index}: #{row.to_h}"

        # Parse the date
        parsed_date = DateParser.parse(row.fields[0])
        if parsed_date[:success]
          date = parsed_date[:date]
        else
          return { success: false, error: parsed_date[:error] }
        end

        #Parse the amount
        amount = row.fields[2]&.tr('R$', '')&.tr('.', '')&.tr(',', '.')&.strip&.to_f || 0.0

        obj_data = { date: date, description: row[1], amount: amount }

        record = model.new(obj_data)
        unless record.save
          Rails.logger.error "Failed to save record: #{record.errors.full_messages.join(', ')}"
          return { success: false, error: "Failed to save record #{record.errors.full_messages.join(', ')}" }
        end

        Rails.logger.info "Record saved successfully: #{record.inspect}"
      end
    rescue CSV::MalformedCSVError => e
      Rails.logger.error "Malformed CSV error: #{e.message}"
      return { success: false, error: "Malformed CSV file: #{e.message}" }
    end
    # If no errors occurred, return success
    { success: true }
  end
end
