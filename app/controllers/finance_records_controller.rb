class FinanceRecordsController < ApplicationController
  require 'csv'

  def new
  end

  def show
    @csv_data1 = FinanceRecord.all
    @csv_data2 = FinanceRecord2.all
  end

  def create
    file1 = params[:file1].path
    file2 = params[:file2].path
    save_data_to_db(file1, file2)

      redirect_to action: :show
  end

  def delete_all
    FinanceRecord.delete_all
    redirect_to root_path, notice: "All records have been deleted."
  end

  private

  def save_data_to_db (file1, file2)
    save_data_to_model(file1, FinanceRecord)
    save_data_to_model(file2, FinanceRecord2)
  end

  def save_data_to_model(file, model)
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

end
