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
    @csv_data1 = FinanceRecord.for_current_user.all
    @csv_data2 = FinanceRecord2.for_current_user.all

    if @csv_data1.present? && @csv_data2.present?
      match(@csv_data1, @csv_data2)
    end

  end

  def create
    @file1 = params[:file1]
    @file2 = params[:file2]

    service_validator = ReconciliationCsvFileValidator.new(@file1, @file2)
    result_csv_validator = service_validator.validate

    unless result_csv_validator[:success]
      flash.now[:alert] = result_csv_validator[:error]
      render :index, status: :unprocessable_entity
      return
    end
    service_data_saver = ReconciliationDataSaver.new(@file1, @file2, FinanceRecord, FinanceRecord2)
    result_data_saver = service_data_saver.call

    if result_data_saver[:success]
      redirect_to reconciliations_path, notice: "Reconciliation completed successfully."
    else
      flash.now[:alert] = result_data_saver[:error]
      render :index, status: :unprocessable_entity
    end
  end

  def delete_all
    FinanceRecord.for_current_user.delete_all
    FinanceRecord2.for_current_user.delete_all

    redirect_to root_path, notice: "All records have been deleted."
  end

  def download_pdf
    # Initialize the variables needed for the view
    @csv_data1 = FinanceRecord.for_current_user.all
    @csv_data2 = FinanceRecord2.for_current_user.all

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
end
