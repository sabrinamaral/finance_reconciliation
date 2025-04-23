class CashFlowsController < ApplicationController

  def new
    @cash_flow_records = CashFlow.all
  end

  def create
    unless params[:cash_flow].present?
      flash.now[:alert] = 'Please upload a CSV file.'
      @cash_flow_records = CashFlow.order(date: :asc) # Ensure transactions are loaded
      render :index, status: :unprocessable_entity
      return
    end

    @csv_file = params[:cash_flow][:file]

    # Check if the file has a valid content type
    unless validate_csv(@csv_file)
      flash[:alert] = 'Uploaded file must be a valid CSV format'
      @cash_flow_records = CashFlow.order(date: :asc) # Ensure transactions are loaded
      render :index, status: :unprocessable_entity
      return
    end

    # Process the CSV file
    result = CashFlow.import_from_csv(@csv_file)

    if result[:success]
      flash[:notice] = 'Cash flow records are successfully created.'
    else
      flash[:alert] = result[:error] || 'CSV headers must be: date, description, amount, transaction_type.'
      @cash_flow_records = CashFlow.order(date: :asc) # Ensure transactions are loaded
      render :index, status: :unprocessable_entity
      return
    end

    redirect_to cash_flows_path
  end

  def index
    @cash_flow_records = CashFlow.order(date: :asc)
  end

  def edit
    @cash_flow_records = CashFlow.find(params[:id])
  end

  def update
    @cash_flow_records = CashFlow.find(params[:id])
    if @cash_flow_records.update(cash_flow_params)
      redirect_to cash_flows_path, notice: 'Record was successfully updated.'
    else
      @cash_flow_records = CashFlow.all
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @cash_flow_record = CashFlow.find(params[:id])
    if @cash_flow_record.destroy
      render json: {message: 'Record was successfully deleted.' }, status: :ok
    else
      render json: {message: 'Failed to delete the record'}, status: :unprocessable_entity
    end
  end

  def delete_all
    CashFlow.delete_all

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

  private

  def cash_flow_params
    params.require(:cash_flow).permit(:date, :description, :amount)
  end

  def validate_csv(file)
    return false  unless file.respond_to?(:content_type)
      content_type = file.content_type
      content_type == "text/csv"
  end

  def headers_match?(headers)
    headers.sort == CashFlow::EXPECTED_HEADERS.sort
  end

  def is_number?(string)
    true if Float(string) rescue false
  end
end
