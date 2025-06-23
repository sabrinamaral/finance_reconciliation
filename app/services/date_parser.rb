class DateParser
  def self.parse(date_string)
    return { success: false, error: "Date string is nil"} if date_string.nil?

    formats = ['%d/%m/%Y', '%d-%m-%Y','%d/%m/%y', '%d-%m-%y' ]
    formats.each do |format|
      begin
        date = Date.strptime(date_string, format)
        if date.year > 1980 && date.month.between?(1, 12) && date.day.between?(1, 31)
          return  { success: :success, date: date }
        end
      rescue ArgumentError
        next
      end
    end
    { success: false, error: "Invalid date format" }
  end
end
