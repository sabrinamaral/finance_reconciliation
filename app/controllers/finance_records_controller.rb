class FinanceRecordsController < ApplicationController
  require 'csv'

  def new
  @file1 = FinanceRecord.new
  @file2 = FinanceRecord2.new
  end

  def show
    @csv_data1 = FinanceRecord.all
    @csv_data2 = FinanceRecord2.all

    match(@csv_data1, @csv_data2)
  end

  def create
    file1 = params[:file1].path
    file2 = params[:file2].path

    save_data_to_db(file1, FinanceRecord)
    save_data_to_db(file2, FinanceRecord2)

    redirect_to action: :show
  end

  def delete_all
    FinanceRecord.delete_all
    FinanceRecord2.delete_all

    redirect_to root_path, notice: "All records have been deleted."
  end

  private

  def save_data_to_db(file, model)
    CSV.foreach(file, headers: true) do |row|
      amount = row.fields[2..3].join.tr('"', '').tr('R$', '').tr(',', '.').to_f || 0.0

      unless amount.zero? || amount.nil?
        obj_data = {
          date: row[0],
          description: row[1],
          amount: amount
        }
      end
      record = model.new(obj_data)
      unless record.save
        puts "Failed to save record: #{record.errors.full_messages.join(", ")}"
      end
    end
  end

  def match (csv_data1, csv_data2)
    @results = {}

    csv_data1.each do |record1|
      match = csv_data2.find { |record2| record1.date == record2.date && record1.amount == record2.amount }
        @results[record1] = false
        if match
          @results[record1] = true
        end
    end

    csv_data2.each do |record2|
      match = csv_data1.find { |record1| record2.date == record1.date && record2.amount == record1.amount }
        @results[record2] = false
        if match
          @results[record2] = true
        end
    end

  end
end
