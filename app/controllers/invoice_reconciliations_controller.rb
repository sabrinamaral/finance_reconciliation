class InvoiceReconciliationsController < ApplicationController
  before_action :set_audit
  before_action :set_period, only: [:index, :create, :download_pdf,
                                    :toggle_checked, :bulk_check]

  def index
    load_records
  end

  def create
    @file = params[:file]

    unless @file
      load_records
      flash.now[:alert] = "Please select a file."
      render :index, status: :unprocessable_entity
      return
    end

    service_validator = ReconciliationCsvFileValidator.new(@file, nil)
    result_csv_validator = service_validator.validate_single

    unless result_csv_validator[:success]
      load_records
      flash.now[:alert] = result_csv_validator[:error]
      render :index, status: :unprocessable_entity
      return
    end

    service_data_saver = InvoiceDataSaver.new(@file, FinanceRecord4, @period)
    result = service_data_saver.call

    if result[:success]
      ensure_matches_exist
      match
      redirect_to invoice_reconciliations_path(period_id: @period.id),
                  notice: "Invoices uploaded and reconciled successfully."
    else
      load_records
      flash.now[:alert] = result[:error]
      render :index, status: :unprocessable_entity
    end
  end

  def delete_all
    period = @audit.audit_periods.find_by(id: params[:period_id])
    if period
      FinanceRecord4.for_current_user.where(audit_period: period).destroy_all
      InvoiceMatch.joins(:finance_record)
                  .where(finance_records: { audit_period_id: period.id })
                  .update_all(finance_record4_id: nil, checked: false, reconciled: false)
    end
    redirect_to invoice_reconciliations_path, notice: "All invoices for this period have been deleted."
  end

  def download_pdf
    load_records
    html = render_to_string(template: 'invoice_reconciliations/pdf', layout: 'pdf')
    pdf = Grover.new(html).to_pdf
    send_data pdf,
              filename: "invoices_#{@period.label}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def toggle_checked
    model  = params[:model] == "FinanceRecord4" ? FinanceRecord4 : InvoiceMatch
    record = model == FinanceRecord4 ? model.for_current_user.find(params[:id]) : model.find(params[:id])
    record.update(checked: !record.checked)
    render json: { checked: record.checked }
  end

  def bulk_check
    ids_by_model = params[:ids_by_model] || {}

    if ids_by_model["InvoiceMatch"].present?
      InvoiceMatch.where(id: ids_by_model["InvoiceMatch"]).update_all(checked: true)
    end

    if ids_by_model["FinanceRecord4"].present?
      FinanceRecord4.for_current_user.where(id: ids_by_model["FinanceRecord4"]).update_all(checked: true)
    end

    render json: { success: true }
  end

  private

  def set_audit
    @audit = Audit.find_by(user_id: Current.user.id)
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
      @period = @audit.audit_periods.order(year: :desc, month: :desc).first
      unless @period
        @period = @audit.audit_periods.create!(month: Date.today.month,
                                              year: Date.today.year)
      end
    end
  end

  def load_records
    @periods = @audit.audit_periods.order(year: :asc, month: :asc)

    ensure_matches_exist

    @bank_records = FinanceRecord.for_current_user
                                .where(audit_period: @period)
                                .includes(:invoice_match)
                                .order(date: :asc, id: :asc)

    @invoice_data = FinanceRecord4.for_current_user
                                  .where(audit_period: @period)
                                  .order(date: :asc, id: :asc)
  end

  # Ensures every bank record in this period has an InvoiceMatch row
  def ensure_matches_exist
    FinanceRecord.for_current_user.where(audit_period: @period).find_each do |record|
      InvoiceMatch.find_or_create_by!(finance_record: record)
    end
  end

  # Attempts to auto-match bank records with invoices by date + amount
  def match
    invoices = FinanceRecord4.for_current_user
                            .where(audit_period: @period)
                            .to_a

    InvoiceMatch.joins(:finance_record)
                .where(finance_records: { audit_period_id: @period.id }, reconciled: false)
                .each do |invoice_match|
      bank = invoice_match.finance_record

      found = invoices.find do |invoice|
        invoice.date == bank.date &&
        invoice.amount == bank.amount &&
        invoice.invoice_match&.reconciled != true
      end

      if found
        invoice_match.update(finance_record4: found, reconciled: true, checked: true)
        found.update(reconciled: true, checked: true)
      end
    end
  end
end
