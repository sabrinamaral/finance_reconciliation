class ReconciliationsController < ApplicationController

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
    @file1 = params[:file1]
    @file2 = params[:file2]

    return unless validate_csv_file

    save_data_to_db(@file1, FinanceRecord) if @file1.respond_to?(:path)
    save_data_to_db(@file2, FinanceRecord2) if @file2.respond_to?(:path)

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
      amount = row.fields[2]&.tr('R$', '')&.tr('.', '')&.tr(',', '.')&.strip&.to_f || 0.0

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

  def match(csv_data1, csv_data2)

    csv_data1.each do |record1|
      match = csv_data2.find do |record2|
        record1[:date] == record2[:date] &&
        record1[:amount] == record2[:amount] && !record2[:reconciled]
      end
      if match
        match[:reconciled] = true
        match.save
      end
    end

    csv_data2.each do |record2|
      match = csv_data1.find do |record1|
          record2[:date] == record1[:date] &&
          record2[:amount] == record1[:amount] &&
          !record1[:reconciled]
      end
      if match
        match[:reconciled] = true
        match.save
      end
    end
  end

  private

  def validate_csv_file
    if @file1.present? && @file2.present?
      content_type1 = @file1.content_type
      content_type2 = @file2.content_type
      if (content_type1 == 'text/csv') && (content_type2 == 'text/csv')
        true
      else
        flash.now[:alert] = 'Please upload CSV files only.'
        render :new, status: :unprocessable_entity
        false
      end
    else
      flash.now[:alert] = 'Please upload both files.'
      render :new, status: :unprocessable_entity
      false
    end
  end
end
