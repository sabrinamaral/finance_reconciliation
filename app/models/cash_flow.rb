class CashFlow < ApplicationRecord
  require 'csv'
  belongs_to :user
  scope :for_current_user, -> { Current.user ? where(user_id: Current.user.id) : none}

  TRANSACTION_TYPES = { "D" => 0, "C" => 1 }.freeze # debit / credit
  COLUMNS = %w[date description amount transaction_type].freeze
  COLUMNS_ERROR = "CSV must have #{COLUMNS.size} columns in this order: " \
                  "date, description, amount and type (D or C). Header names can be in any language.".freeze

  validates :date, presence: true
  validates :description, presence: true
  validates :amount, presence: true, numericality: true
  validates :transaction_type, presence: true

  class ImportError < StandardError; end

  def self.import_from_csv(file, user)
    rows = CSV.read(file, headers: true, encoding: "bom|utf-8")
    return { success: true } if rows.empty?

    return { success: false, error: COLUMNS_ERROR } if rows.headers.compact.size < COLUMNS.size

    records = rows.map { |row| COLUMNS.zip(row.fields.first(COLUMNS.size)).to_h }

    date_order = DateParser.detect_order(records.map { |attributes| attributes['date'] })
    return { success: false, error: DateParser::CONFLICT_ERROR } if date_order == :conflict

    transaction do
      records.each.with_index(2) do |attributes, line| # line 1 is the header
        parsed_date = DateParser.parse(attributes['date'], order: date_order)

        raise ImportError, "#{parsed_date[:error]} (row #{line})" unless parsed_date[:success]

        attributes['date']   = parsed_date[:date]
        attributes['amount'] = parse_amount(attributes['amount'])

        raw_type = attributes['transaction_type']
        type = TRANSACTION_TYPES[raw_type.to_s.strip.upcase]
        raise ImportError, "Invalid entry type '#{raw_type}'. Expected 'C' or 'D'. (row #{line})" unless type
        attributes['transaction_type'] = type

        record = user.cash_flows.new(attributes)
        raise ImportError, "Row #{line}: #{record.errors.full_messages.join(', ')}" unless record.save
      end
    end
    { success: true }
  rescue ImportError => e
    { success: false, error: e.message }
  rescue CSV::MalformedCSVError => e
    { success: false, error: "Malformed CSV file: #{e.message}" }
  end

  # "R$ 1.234,56" -> "1234.56"; blank stays nil so the presence validation catches it
  def self.parse_amount(value)
    return nil if value.blank?

    value.gsub(/[[:space:]]/, '').delete('R$').delete('.').tr(',', '.')
  end
end
