require 'csv'

class ReconciliationCsvFileValidator
  def initialize(file1, file2)
    @file1 = file1
    @file2 = file2
  end

  def validate
    if @file1.present? && @file2.present?
      content_type1 = @file1.content_type
      content_type2 = @file2.content_type

      if (content_type1 == 'text/csv') && (content_type2 == 'text/csv')
        file1_data = CSV.read(@file1.path)
        file2_data = CSV.read(@file2.path)

        if file1_data.empty? || file2_data.empty?
          return { success: false, error: 'One or both files are empty.'}
        end

        # Check if the files have more than the headears
        if file1_data.size <= 1 || file2_data.size <= 1
          return { success: false, error: "One or both files contain only headers."}
        end
        # Validate rows in file1
        invalid_rows_file1 = file1_data.each_with_index.select do |row, index|
          row.compact.size < 3
        end
        # Validate rows in file2
        invalid_rows_file2 = file2_data.each_with_index.select do |row, index|
          row.compact.size < 3
        end
        if invalid_rows_file1.any? || invalid_rows_file2.any?
          return { success: false, error: "Invalid rows found in the files. Please ensure that all rows have content in all columns." }
        end
        return { success: true }
      else
        return { success: false, error: 'Please upload CSV files only' }
      end
    else
      return { success: false, error: 'Please upload both files' }
    end
  end
end
