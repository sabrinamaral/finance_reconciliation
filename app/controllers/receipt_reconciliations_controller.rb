class ReceiptReconciliationsController < ApplicationController
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

    service_data_saver = ReceiptDataSaver.new(@file, FinanceRecord3, @period)
    result = service_data_saver.call

    if result[:success]
      ensure_matches_exist
      match
      redirect_to receipt_reconciliations_path(period_id: @period.id),
                  notice: "Receipts uploaded and reconciled successfully."
    else
      load_records
      flash.now[:alert] = result[:error]
      render :index, status: :unprocessable_entity
    end
  end

  def delete_all
    period = @audit.audit_periods.find_by(id: params[:period_id])
    if period
      FinanceRecord3.for_current_user.where(audit_period: period).destroy_all
      ReceiptMatch.joins(:finance_record)
                  .where(finance_records: { audit_period_id: period.id })
                  .update_all(finance_record3_id: nil, checked: false, reconciled: false)
    end
    redirect_to receipt_reconciliations_path, notice: "All receipts for this period have been deleted."
  end

  def download_pdf
    load_records
    html = render_to_string(template: 'receipt_reconciliations/pdf', layout: 'pdf')
    pdf = Grover.new(html).to_pdf
    send_data pdf,
              filename: "receipts_#{@period.label}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

def toggle_checked
  model = params[:model] == "FinanceRecord3" ? FinanceRecord3 : ReceiptMatch
  record = model == FinanceRecord3 ? model.for_current_user.find(params[:id]) : model.find(params[:id])
  record.update(checked: !record.checked)
  render json: { checked: record.checked }
end

def bulk_check
  ids_by_model = params[:ids_by_model] || {}

  if ids_by_model["ReceiptMatch"].present?
    ReceiptMatch.where(id: ids_by_model["ReceiptMatch"]).update_all(checked: true)
  end

  if ids_by_model["FinanceRecord3"].present?
    FinanceRecord3.for_current_user.where(id: ids_by_model["FinanceRecord3"]).update_all(checked: true)
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
      @period = @audit.audit_periods.order(year: :asc, month: :asc).first
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
                                .where("amount < 0")
                                .includes(:receipt_match)
                                .order(date: :asc, id: :asc)

    @receipt_data = FinanceRecord3.for_current_user
                                  .where(audit_period: @period)
                                  .order(date: :asc, id: :asc)
  end

  # Ensures every bank record in this period has a ReceiptMatch row,
  # so we always have a place to store its checked/reconciled state
  def ensure_matches_exist
    FinanceRecord.for_current_user.where(audit_period: @period).find_each do |record|
      ReceiptMatch.find_or_create_by!(finance_record: record)
    end
  end

  # Attempts to auto-match bank records with receipts by date + amount
  def match
    receipts = FinanceRecord3.for_current_user
                            .where(audit_period: @period)
                            .to_a

    ReceiptMatch.joins(:finance_record)
                .where(finance_records: { audit_period_id: @period.id }, reconciled: false)
                .each do |receipt_match|
      bank = receipt_match.finance_record

      found = receipts.find do |receipt|
        receipt.date == bank.date &&
        receipt.amount == bank.amount &&
        receipt.receipt_match&.reconciled != true
      end

      if found
        receipt_match.update(finance_record3: found, reconciled: true, checked: true)
        found.update(reconciled: true, checked: true)  # ← marca o lado do recibo também
      end
    end
  end
end
