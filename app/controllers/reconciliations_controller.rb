class ReconciliationsController < ApplicationController
  def index
    load_records()
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
      match(FinanceRecord.for_current_user.all, FinanceRecord2.for_current_user.all)
      redirect_to reconciliations_path, notice: "Reconciliation completed successfully."
    else
      flash.now[:alert] = result_data_saver[:error]
      render :index, status: :unprocessable_entity
    end

  end

  def toggle_checked
    model = params[:model] == "FinanceRecord2" ? FinanceRecord2 : FinanceRecord
    record = model.for_current_user.find(params[:id])
    record.update(checked: !record.checked)
    render json: { checked: record.checked }
  end

  def bulk_check
    ids_by_model = params[:ids_by_model] || {}

    ids_by_model.each do |model_name, ids|
      model = model_name == "FinanceRecord2" ? FinanceRecord2 : FinanceRecord
      model.for_current_user.where(id: ids).update_all(checked: true)
    end

    render json: { success: true }
  end

  def delete_all
    FinanceRecord.for_current_user.delete_all
    FinanceRecord2.for_current_user.delete_all

    redirect_to root_path, notice: "All records have been deleted."
  end

  def download_pdf
    # Initialize the variables needed for the view
    load_records()

    # Render your HTML template
    html = render_to_string(template: 'reconciliations/pdf', layout: 'pdf')
    pdf = Grover.new(html).to_pdf

    send_data pdf,
              filename: "reconciliation.pdf",
              type: "application/pdf",
              disposition: "attachment" # "inline" to display in the browser, "attachment" to force download
  end

  def audit
    load_records

    unreconciled1 = @csv_data1.where(reconciled: false)
    unreconciled2 = @csv_data2.where(reconciled: false)

    service = ClaudeAuditService.new(unreconciled1, unreconciled2)
    result = service.call

    if result[:success]
      @analysis = result[:analysis]
    else
      flash.now[:alert] = result[:error]
    end

    render :audit
  end

  private

  def load_records
    @csv_data1 = FinanceRecord.for_current_user.order(date: :asc, id: :asc)
    @csv_data2 = FinanceRecord2.for_current_user.order(date: :asc, id: :asc)
  end

  def match(csv_data1, csv_data2)
    records2 = csv_data2.to_a

    csv_data1.each do |record1|
      found = records2.find do |record2|
        record1[:date] == record2[:date] &&
        record1[:amount] == record2[:amount] &&
        !record2[:reconciled]
      end

      if found
        record1.update(reconciled: true, checked: true)
        found.update(reconciled: true, checked: true)
      end
    end
  end
end
