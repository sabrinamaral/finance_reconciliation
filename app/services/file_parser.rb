require 'csv'

module FileParser
  # Base class for file reading errors, so callers can rescue them all at once.
  class Error < StandardError; end

  # Raised when an Excel date column has both real dates and text.
  class MixedDateFormatsError < Error
    def initialize(msg = "The date column mixes real dates and text. Format the whole date column as Text " \
                        "(or as Date) in Excel and upload the file again.")
      super
    end
  end

  # Raised when the file can't be read (corrupted, wrong encoding, unsupported format).
  class UnreadableFileError < Error
    def initialize(msg = "The file could not be read. Check that it is a valid CSV file saved as UTF-8.")
      super
    end
  end

  ALLOWED_CONTENT_TYPES = %w[
    text/csv
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  MAX_FILE_SIZE = 5.megabytes

  def parse_file(file)
    case file.content_type
    when 'text/csv'
      CSV.read(file.path, headers: true, encoding: "bom|utf-8")
    else
      spreadsheet = Roo::Spreadsheet.open(file.path, clean: true)
      headers = spreadsheet.row(1)
      rows = spreadsheet.each_with_index.filter_map { |row, index| row unless index.zero? }

      check_date_column!(rows)

      rows.map do |row|
        normalized_row = row.map { |cell| cell.is_a?(Date) ? cell.strftime('%d/%m/%Y') : cell }
        CSV::Row.new(headers, normalized_row)
      end
    end
  rescue Error
    raise
  rescue StandardError => e
    Rails.logger.warn "Could not read #{file.original_filename}: #{e.class}: #{e.message}"
    raise UnreadableFileError
  end

  private

  # Excel only converts the text dates that are valid in its own locale (e.g. US MM/DD)
  # and leaves the others as text. A date column with both types likely has day and month
  # swapped in the converted rows, so the file is rejected instead of guessing.
  def check_date_column!(rows)
    cells = rows.map(&:first).select(&:present?)
    return unless cells.any? { |cell| cell.is_a?(Date) } && cells.any? { |cell| cell.is_a?(String) }

    raise MixedDateFormatsError
  end
end
