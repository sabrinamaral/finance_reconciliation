# Parses a CSV row into a normalized hash: { date:, description:, amount: }
# Handles date parsing, currency formatting, and debit/credit sign application.
class CsvImporter
  VALID_TYPES = %w[C D].freeze

  Result = Struct.new(:success, :data, :error, keyword_init: true)

  def self.parse_row(row, date_order: :dmy)
    parsed_date = DateParser.parse(row.fields[0], order: date_order)
    return Result.new(success: false, error: parsed_date[:error]) unless parsed_date[:success]

    amount = parse_amount(row.fields[2])
    return Result.new(success: false, error: "Invalid amount '#{row.fields[2]}'.") if amount.nil?

    entry_type = row.fields[3].to_s.strip.upcase
    unless VALID_TYPES.include?(entry_type)
      return Result.new(success: false, error: "Invalid entry type '#{entry_type}'. Expected 'C' or 'D'.")
    end

    amount = -amount if entry_type == "D"

    Result.new(
      success: true,
      data: { date: parsed_date[:date], description: row[1], amount: amount }
    )
  end

  # Accepts numbers from Excel (3000.5) or Brazilian text ("R$ 3.000,50", "-3.000,50").
  # Returns the absolute value as BigDecimal (the sign comes from the C/D column),
  # or nil when the value is blank or not a number.
  def self.parse_amount(value)
    return value.to_d.abs if value.is_a?(Numeric)

    text = value.to_s.gsub(/[[:space:]]/, '').delete('R$').delete('.').tr(',', '.')
    BigDecimal(text, exception: false)&.abs
  end
end
