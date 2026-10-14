require 'csv'

class ReconciliationCsvFileValidator
  include FileParser

  def initialize(file1, file2)
    @file1 = file1
    @file2 = file2
  end

  def validate
    unless @file1.present? && @file2.present?
      return { success: false, error: 'Please upload both files' }
    end

    unless (valid_content_type?(@file1)) && (valid_content_type?(@file2))
      return { success: false, error: 'Please upload CSV or Excel files only' }
    end

    unless valid_size?(@file1) && valid_size?(@file2)
      return { success: false, error: "Files must be at most #{MAX_FILE_SIZE / 1.megabyte} MB" }
    end

    begin
      file1_data = parse_file(@file1)
      file2_data = parse_file(@file2)
    rescue FileParser::Error => e
      return { success: false, error: e.message }
    end

    if file1_data.empty? || file2_data.empty?
      return { success: false, error: 'One or both files have no data rows.'}
    end

    # Validate rows in file1
    invalid_rows = [file1_data, file2_data].any? do |data|
      data.any? do |row|
        row.compact.size < 3
      end
    end

    if invalid_rows
      return {success:false, error: 'Invalid rows found in the files. Enrsure taht all rows and coumns have content.'}
    end

    { success: true }
  end

  def validate_single
    return { success: false, error: "File is missing." } unless @file1
    return { success: false, error: "File must be a CSV." } unless valid_content_type?(@file1)
    return { success: false, error: "File must be at most #{MAX_FILE_SIZE / 1.megabyte} MB." } unless valid_size?(@file1)
    { success: true }
  end

  private

  def valid_content_type?(file)
    ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  def valid_size?(file)
    file.size <= MAX_FILE_SIZE
  end

end
