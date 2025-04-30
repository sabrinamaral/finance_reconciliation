class ReconciliationDataSaver
  def initialize(file, model)
    @file = file
    @model = model
  end

  def call
    CSV.foreach(@file, headers: true) do |row|
      next if row.fields.compact.empty?

      date = DateParser.parse(row.fields[0])
      if date.nil?
        return { success: false, error: "Invalid date format." }
      end

      amount = row.fields[2]&.tr('R$', '')&.tr('.', '')&.tr(',', '.')&.strip&.to_f || 0.0
      unless amount.zero? || amount.nil?
        obj_data = { date: date, description: row[1], amount: amount }
      end
      record = @model.new(obj_data)

      unless record.save
        return { success: false, error: "Failed to save record" }
      end

    end
    { success: true }
  end
end
