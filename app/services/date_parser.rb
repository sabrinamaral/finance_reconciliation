class DateParser
  def self.parse(date_string)
    return nil if date_string.nil?

    formats = ['%d/%m/%Y', '%Y-%m-%d', '%d-%m-%Y']
    formats.each do |format|
      begin
        date = Date.strptime(date_string, format)
        return date if date.year > 1900 && date.month.between?(1, 12) && date.day.between?(1, 31)
      rescue ArgumentError
        next
      end
    end
    nil
  end
end
