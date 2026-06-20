class ReconciliationDataSaver
  include FileParser

  VALID_TYPES = %w[C D].freeze

  def initialize(file1, file2, model1, model2)
    @file1 = file1
    @file2 = file2
    @model1 = model1
    @model2 = model2
    @user = Current.user
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
        Rails.logger.info "Processing row #{index + 1}: #{row.to_h}"

        # Parse the date
        parsed_date = DateParser.parse(row.fields[0])
        if parsed_date[:success]
          date = parsed_date[:date]
        else
          return { success: false, error: parsed_date[:error] }
        end

        # Parse the amount (always positive at this point)
        amount_str = row.fields[2]&.gsub(/[[:space:]]/, '')&.tr('R$', '')
        amount_str = amount_str.gsub('.', '')&.gsub(',', '.')
        amount = amount_str.to_f

        # Parse the entry type (C = credit, D = debit) and apply sign
        entry_type = row.fields[3]&.strip&.upcase

        unless VALID_TYPES.include?(entry_type)
          error_msg = "Invalid entry type '#{entry_type}' at row #{index + 1}. Expected 'C' or 'D'."
          Rails.logger.error error_msg
          return { success: false, error: error_msg }
        end

        amount = -amount if entry_type == "D"

        obj_data = { date: date, description: row[1], amount: amount }
        record = model.new(obj_data)
        record.user = @user

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
    { success: true }
  end
end
