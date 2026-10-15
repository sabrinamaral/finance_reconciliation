class CashFlowsController < ApplicationController

  def create
    file = params.dig(:cash_flow, :file)
    return render_upload_error("Please upload a CSV file.") unless file
    return render_upload_error("Uploaded file must be a CSV.") unless csv_file?(file)
    return render_upload_error("Uploaded file must be at most #{FileParser::MAX_FILE_SIZE / 1.megabyte} MB.") if file.size > FileParser::MAX_FILE_SIZE

    result = CashFlow.import_from_csv(file, Current.user)
    return render_upload_error(result[:error]) unless result[:success]

    redirect_to cash_flows_path, notice: "Cash flow records are successfully created."
  end

  def index
    @cash_flow_records = CashFlow.for_current_user.order(date: :asc)
  end

  def update
    @cash_flow_records = CashFlow.for_current_user.find(params[:id])
    if @cash_flow_records.update(cash_flow_params)
      redirect_to cash_flows_path, notice: 'Record was successfully updated.'
    else
      @cash_flow_records = CashFlow.for_current_user.all
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @cash_flow_record = CashFlow.for_current_user.find(params[:id])
    if @cash_flow_record.destroy
      render json: {message: 'Record was successfully deleted.' }, status: :ok
    else
      render json: {message: 'Failed to delete the record'}, status: :unprocessable_entity
    end
  end

  def delete_all
    CashFlow.for_current_user.delete_all

    redirect_to cash_flows_path, notice: 'All records have been deleted.'
  end

  def set_balance
    @balance = params[:starting_balance]

    if @balance.blank? || !is_number?(@balance)
      render json: {message: 'Balance must be a valid number.'}, status: :unprocessable_entity
    else
      session[:starting_balance] = @balance
      render json: { message: 'Balance was successfully set.'}
    end
  end

  def reset_balance
    session[:starting_balance] = 0
    @balance = session[:starting_balance]
    redirect_to cash_flows_path, notice: 'Balance was successfully reset.'
  end

  def add_transaction
    @transaction = Current.user.cash_flows.new(cash_flow_params)

    if @transaction.save
      redirect_to cash_flows_path, notice: 'Record was successfully saved.'
    else
      @cash_flow_records = CashFlow.for_current_user.all
      render :index, status: :unprocessable_entity
    end
  end

  private

  def cash_flow_params
    params.require(:cash_flow).permit(:date, :description, :amount, :transaction_type)
  end

  def csv_file?(file)
    file.respond_to?(:original_filename) &&
      File.extname(file.original_filename.to_s).casecmp?(".csv")
  end

  def render_upload_error(message)
    flash.now[:alert] = message
    @cash_flow_records = CashFlow.for_current_user.order(date: :asc)
    render :index, status: :unprocessable_entity
  end


  def is_number?(string)
    true if Float(string) rescue false
  end
end
