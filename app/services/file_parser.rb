require 'csv'

module FileParser
    ALLOWED_CONTENT_TYPES = %w[
    text/csv
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  def parse_file(file)
    case file.content_type
    when 'text/csv'
      CSV.read(file.path, headers: true)
    else
      spreadsheet = Roo::Spreadsheet.open(file.path, clean: true)
      headers = spreadsheet.row(1)
      spreadsheet.each_with_index.map do |row, index|
        next if index == 0
        normalized_row = row.map { |cell| cell.is_a?(Date) ? cell.strftime('%d/%m/%Y'): cell }
        CSV::Row.new(headers, normalized_row)
      end.compact
    end
  end
end
