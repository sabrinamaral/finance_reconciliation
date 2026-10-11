class ReceiptReconciliationsController < ApplicationController
  before_action :set_audit
  before_action :set_period, only: [:index, :create, :download_pdf,
                                    :download_excel, :toggle_checked,
                                    :bulk_check]

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
  @bank_records = apply_bank_scope(@bank_records)
  @receipt_data = apply_receipt_scope(@receipt_data)
  html = render_to_string(template: 'receipt_reconciliations/pdf', layout: 'pdf')
  pdf = Grover.new(html).to_pdf
  send_data pdf,
            filename: "receipts_#{@period.label.tr('/', '-')}.pdf",
            type: "application/pdf",
            disposition: "inline"
end

def download_excel
  load_records
  @bank_records = apply_bank_scope(@bank_records)
  @receipt_data = apply_receipt_scope(@receipt_data)
  render xlsx: "download_excel", filename: "receipts_#{@period.label.tr('/', '-')}.xlsx"
end

def toggle_checked
  record = params[:model] == "FinanceRecord3" ?
  FinanceRecord3.for_current_user.find(params[:id]) :
  user_receipt_matches.find(params[:id])
  record.update(checked: !record.checked)
  render json: { checked: record.checked }
end

def bulk_check
  ids_by_model = params[:ids_by_model] || {}

  if ids_by_model["ReceiptMatch"].present?
    user_receipt_matches.where(id: ids_by_model["ReceiptMatch"]).update_all(checked: true)
  end

  if ids_by_model["FinanceRecord3"].present?
    FinanceRecord3.for_current_user.where(id: ids_by_model["FinanceRecord3"]).update_all(checked: true)
  end

  render json: { success: true }
end

private

  def user_receipt_matches
    ReceiptMatch.joins(:finance_record)
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
                                .includes(:receipt_match)
                                .order(date: :asc, id: :asc)

    @receipt_data = FinanceRecord3.for_current_user
                                  .where(audit_period: @period)
                                  .order(date: :asc, id: :asc)
  end

  # Ensures every bank record in this period has a ReceiptMatch row,
  # so we always have a place to store its checked/reconciled state
  def ensure_matches_exist
    FinanceRecord.for_current_user.where(audit_period: @period).where("amount < 0").find_each do |record|
      ReceiptMatch.find_or_create_by!(finance_record: record)
    end
  end

  # Attempts to auto-match bank records with receipts by date + amount
  def match
    receipts = FinanceRecord3.for_current_user
                            .where(audit_period: @period)
                            .to_a

    ReceiptMatch.includes(:finance_record).joins(:finance_record)
                .where(finance_records: { audit_period_id: @period.id }, reconciled: false)
                .where("finance_records.amount < 0")
                .each do |receipt_match|
      bank = receipt_match.finance_record

      found = receipts.find do |receipt|
        receipt.date == bank.date &&
        receipt.amount == bank.amount &&
        !receipt.reconciled
      end

      if found
        receipt_match.update(finance_record3: found, reconciled: true, checked: true)
        found.update(reconciled: true, checked: true)  # ← marca o lado do recibo também
      end
    end
  end

  def apply_bank_scope(records)
    case params[:scope]
    when "reconciled"
      records.select { |r| r.receipt_match&.checked }
    when "unreconciled"
      records.reject { |r| r.receipt_match&.checked }
    else
      records
    end
  end

  def apply_receipt_scope(records)
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
