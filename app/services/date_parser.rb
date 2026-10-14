class DateParser
  SEPARATOR = %r{[/-]}

  FORMATS = {
    dmy: ['%d/%m/%Y', '%d-%m-%Y', '%d/%m/%y', '%d-%m-%y'],
    mdy: ['%m/%d/%Y', '%m-%d-%Y', '%m/%d/%y', '%m-%d-%y']
  }.freeze

  CONFLICT_ERROR = "Inconsistent date formats in file: found both DD/MM and MM/DD dates.".freeze

  # Scans every date of a file to decide between DD/MM (:dmy) and MM/DD (:mdy).
  # A number above 12 can only be a day, which reveals the order.
  # Returns :conflict when both orders appear; defaults to :dmy when all dates are ambiguous.
  def self.detect_order(date_strings)
    day_first   = false
    month_first = false

    date_strings.each do |value|
      first, second = value.to_s.strip.split(SEPARATOR).first(2).map(&:to_i)
      next if first.nil? || second.nil? || first > 31 # skip blanks and year-first values

      day_first   ||= first > 12
      month_first ||= second > 12
    end

    return :conflict if day_first && month_first

    month_first ? :mdy : :dmy
  end

  def self.parse(date_string, order: :dmy)
    return { success: false, error: "Date string is nil" } if date_string.nil?

    FORMATS.fetch(order).each do |format|
      begin
        date = Date.strptime(date_string.to_s, format)
        if date.year > 1980 && date.month.between?(1, 12) && date.day.between?(1, 31)
          return { success: :success, date: date }
        end
      rescue ArgumentError
        next
      end
    end
    { success: false, error: "Invalid date format" }
  end
end
