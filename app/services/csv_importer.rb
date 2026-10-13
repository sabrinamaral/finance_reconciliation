# Parses a CSV row into a normalized hash: { date:, description:, amount: }
# Handles date parsing, currency formatting, and debit/credit sign application.
class CsvImporter
  VALID_TYPES = %w[C D].freeze

  Result = Struct.new(:success, :data, :error, keyword_init: true)

  def self.parse_row(row, date_order: :dmy)
    parsed_date = DateParser.parse(row.fields[0], order: date_order)

    return Result.new(success: false, error: parsed_date[:error]) unless parsed_date[:success]

    amount_str = row.fields[2]&.gsub(/[[:space:]]/, '')&.tr('R$', '')
    amount_str = amount_str&.gsub('.', '')&.gsub(',', '.')
    amount     = amount_str.to_f

    entry_type = row.fields[3]&.strip&.upcase
    unless VALID_TYPES.include?(entry_type)
      return Result.new(success: false, error: "Invalid entry type '#{entry_type}'. Expected 'C' or 'D'.")
    end

    amount = -amount if entry_type == "D"

    Result.new(
      success: true,
      data: { date: parsed_date[:date], description: row[1], amount: amount }
    )
  end
end
