require 'csv'
class ReconciliationsController < ApplicationController
  def new
    @file1 = FinanceRecord.new
    @file2 = FinanceRecord2.new

    respond_to do |format|
      format.html { head :no_content}
      format.json { render json: {file1: @file1, file2: @file2} }
    end
  end

  def index
    @csv_data1 = FinanceRecord.all
    @csv_data2 = FinanceRecord2.all

    match(@csv_data1, @csv_data2)

  end

  def create
    @file1 = params[:file1]
    @file2 = params[:file2]

    unless validate_csv_file
      flash.now[:alert] ||= "Please upload both files"
      render :index, status: :unprocessable_entity
      return
    end

    # Process the first file
    if @file1.respond_to?(:path)
      result = ReconciliationDataSaver.new(@file1, FinanceRecord).call
      unless result[:success]
        flash.now[:alert] = result[:error]
        render :index, status: :unprocessable_entity
        return
      end
    end

    # Process the second file
    if @file2.respond_to?(:path)
      result = ReconciliationDataSaver.new(@file2, FinanceRecord2).call
      unless result[:success]
        flash.now[:alert] = result[:error]
        render :index, status: :unprocessable_entity
        return
      end
    end

    redirect_to action: :index
    return
  end

  def delete_all
    FinanceRecord.delete_all
    FinanceRecord2.delete_all

    redirect_to root_path, notice: "All records have been deleted."
  end

  def download_pdf
    # Initialize the variables needed for the view
    @csv_data1 = FinanceRecord.all
    @csv_data2 = FinanceRecord2.all

    # Render your HTML template
    html = render_to_string(template: 'reconciliations/pdf', layout: 'pdf')
    pdf = Grover.new(html).to_pdf

    send_data pdf,
              filename: "reconciliation.pdf",
              type: "application/pdf",
              disposition: "attachment" # "inline" to display in the browser, "attachment" to force download
  end

  private

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

  def validate_csv_file
    if @file1.present? && @file2.present?
      content_type1 = @file1.content_type
      content_type2 = @file2.content_type
      if (content_type1 == 'text/csv') && (content_type2 == 'text/csv')
        true
      else
        flash.now[:alert] = 'Please upload CSV files only'
        false
      end
    else
      flash.now[:alert] = 'Please upload both files'
      false
    end
  end
end
