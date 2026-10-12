class InvoiceReconciliationsController < ApplicationController
  before_action :set_audit
  before_action :set_period, only: [:index, :create, :download_pdf,
                                    :download_excel, :toggle_checked, :bulk_check]

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

    unless period
      redirect_to invoice_reconciliations_path, alert: "Period not found."
      return
    end

    ActiveRecord::Base.transaction do
      FinanceRecord4.for_current_user.where(audit_period: period).destroy_all
      InvoiceMatch.joins(:finance_record)
                  .where(finance_records: { audit_period_id: period.id })
                  .update_all(finance_record4_id: nil, checked: false, reconciled: false)
    end

    redirect_to invoice_reconciliations_path, notice: "All invoices for this period have been deleted."
  end

  def download_pdf
    load_records
    @bank_records = apply_bank_scope(@bank_records)
    @invoice_data = apply_invoice_scope(@invoice_data)
    pdf = ReconciliationReportPdf.new(
      title: "Invoices Reconciliation Report — #{@period.label}",
      sections: [
        { title: "Bank Statement", records: @bank_records, checked: ->(r) { r.invoice_match&.checked } },
        { title: "Invoices",       records: @invoice_data, checked: ->(r) { r.checked } }
      ]
    ).render

    send_data pdf,
              filename: "invoices_#{@period.label.tr('/', '-')}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  def download_excel
    load_records
    @bank_records = apply_bank_scope(@bank_records)
    @invoice_data = apply_invoice_scope(@invoice_data)
    render xlsx: "download_excel", filename: "invoices_#{@period.label.tr('/', '-')}.xlsx"
  end

  def toggle_checked
    record = params[:model] == "FinanceRecord4" ? FinanceRecord4.for_current_user.find(params[:id]) : user_invoice_matches.find(params[:id])
    record.update(checked: !record.checked)
    render json: { checked: record.checked }
  end

  def bulk_check
    ids_by_model = params[:ids_by_model] || {}

    if ids_by_model["InvoiceMatch"].present?
      user_invoice_matches.where(id: ids_by_model["InvoiceMatch"]).update_all(checked: true)
    end

    if ids_by_model["FinanceRecord4"].present?
      FinanceRecord4.for_current_user.where(id: ids_by_model["FinanceRecord4"]).update_all(checked: true)
    end

    render json: { success: true }
  end

  private

  def user_invoice_matches
    InvoiceMatch.joins(:finance_record)
                .where(finance_records: { user_id: Current.user.id })
  end

  def set_audit
    @audit = Audit.find_by(user_id: Current.user.id)
    unless @audit
      @audit = Audit.create!(name: "Auditoria Principal", user_id: Current.user.id)
    end
  end

  def set_period
    if params[:period_id].present?
      @period = @audit.audit_periods.find(params[:period_id])
    elsif session[:current_period_id].present?
      @period = @audit.audit_periods.find_by(id: session[:current_period_id])
    end

    @period ||= @audit.audit_periods.order(year: :asc, month: :asc).first || @audit.audit_periods.create!(month: Date.today.month,
    year: Date.today.year)

    session[:current_period_id] = @period.id
  end

  def load_records
    @periods = @audit.audit_periods.order(year: :asc, month: :asc)

    ensure_matches_exist

    @bank_records = FinanceRecord.for_current_user
                                .where(audit_period: @period)
                                .where("amount < 0")
                                .includes(:invoice_match)
                                .order(date: :asc, id: :asc)

    @invoice_data = FinanceRecord4.for_current_user
                                  .where(audit_period: @period)
                                  .order(date: :asc, id: :asc)
  end

  # Ensures every bank record in this period has an InvoiceMatch row
  def ensure_matches_exist
    FinanceRecord.for_current_user.where(audit_period: @period).where("amount < 0").find_each do |record|
      InvoiceMatch.find_or_create_by!(finance_record: record)
    end
  end

  # Attempts to auto-match bank records with invoices by date + amount
  def match
    invoices = FinanceRecord4.for_current_user
                            .where(audit_period: @period)
                            .to_a

    InvoiceMatch.includes(:finance_record).joins(:finance_record)
                .where(finance_records: { audit_period_id: @period.id }, reconciled: false)
                .where("finance_records.amount < 0")
                .each do |invoice_match|
      bank = invoice_match.finance_record

      found = invoices.find do |invoice|
        invoice.date == bank.date &&
        invoice.amount == bank.amount &&
        !invoice.reconciled
      end

      if found
        invoice_match.update(finance_record4: found, reconciled: true, checked: true)
        found.update(reconciled: true, checked: true)
      end
    end
  end

  def apply_bank_scope(records)
    case params[:scope]
    when "reconciled"
      records.select { |r| r.invoice_match&.checked }
    when "unreconciled"
      records.reject { |r| r.invoice_match&.checked }
    else
      records
    end
  end

  def apply_invoice_scope(records)
    case params[:scope]
    when "reconciled"
      records.where(checked: true)
    when "unreconciled"
      records.where(checked: false)
    else
      records
    end
  end
end
