class ReconciliationsController < ApplicationController
  before_action :set_audit
  before_action :set_period, only: [:index, :create, :download_pdf, :audit,
                                    :toggle_checked, :bulk_check]

  def index
    load_records
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

    service_data_saver = ReconciliationDataSaver.new(
      @file1, @file2, FinanceRecord, FinanceRecord2, @period
    )
    result_data_saver = service_data_saver.call

    if result_data_saver[:success]
      match(
        FinanceRecord.for_current_user.where(audit_period: @period),
        FinanceRecord2.for_current_user.where(audit_period: @period)
      )
      redirect_to reconciliations_path(period_id: @period.id),
                  notice: "Reconciliation completed successfully."
    else
      flash.now[:alert] = result_data_saver[:error]
      render :index, status: :unprocessable_entity
    end
  end

  def delete_all
    period = @audit.audit_periods.find_by(id: params[:period_id])
    if period
      FinanceRecord.for_current_user.where(audit_period: period).delete_all
      FinanceRecord2.for_current_user.where(audit_period: period).delete_all
    end
    redirect_to root_path, notice: "All records for this period have been deleted."
  end

  def download_pdf
    load_records
    html = render_to_string(template: 'reconciliations/pdf', layout: 'pdf')
    pdf = Grover.new(html).to_pdf
    send_data pdf,
              filename: "reconciliation_#{@period.label}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def audit
    load_records
    unreconciled1 = FinanceRecord.for_current_user
                                .where(audit_period: @period, checked: false)
    unreconciled2 = FinanceRecord2.for_current_user
                                  .where(audit_period: @period, checked: false)

    service = ClaudeAuditService.new(unreconciled1, unreconciled2)
    result = service.call

    if result[:success]
      @analysis = result[:analysis]
    else
      flash.now[:alert] = result[:error]
    end

    render :audit
  end

  def toggle_checked
    model  = params[:model] == "FinanceRecord2" ? FinanceRecord2 : FinanceRecord
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

  private

  def set_audit
    @audit = Audit.find_by(user_id: Current.user.id)

    # Create a default audit if none exists yet
    unless @audit
      @audit = Audit.create!(name: "Auditoria Principal", user_id: Current.user.id)
    end
  end

  def set_period
    if params[:period_id].present?
      @period = @audit.audit_periods.find(params[:period_id])
      session[:current_period_id] = @period.id
    elsif session[:current_period_id].present?
    @period = @audit.audit_periods.find_by(id: session[:current_period_id])
    else
      @period = @audit.audit_periods.order(year: :asc, month: :asc).first
      unless @period
        @period = @audit.audit_periods.create!(month: Date.today.month,
                                              year: Date.today.year)
      end
    end
  end

  def load_records
    @periods  = @audit.audit_periods.order(year: :asc, month: :asc)
    @csv_data1 = FinanceRecord.for_current_user
                              .where(audit_period: @period)
                              .order(date: :asc, id: :asc)
    @csv_data2 = FinanceRecord2.for_current_user
                              .where(audit_period: @period)
                              .order(date: :asc, id: :asc)
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
