class CashFlowsController < ApplicationController

  def new
    @cash_flow_records = CashFlow.all
  end

  def create
    unless params[:cash_flow].present? && params[:cash_flow][:file].present?
      flash.now[:alert] = 'Please upload a CSV file.'
      render 'cash_flows/index', status: :unprocessable_entity
      return
    end

    @csv_file = params[:cash_flow][:file]
    result = CashFlow.import_from_csv(@csv_file)

    if validate_csv(@csv_file)
      if result[:success]
        flash[:notice] = 'Cash flow records are successfully created.'
      else
        flash[:alert] = result[:error]
      end
      redirect_to cash_flows_path
    end
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
      render :index
    end
  end

  def destroy
    @cash_flow_record = CashFlow.find(params[:id])
    if @cash_flow_record.destroy
      render json: {message: 'Record was successfully deleted.'}, status: :ok
    else
      render json: {message: 'Failed to delete the record'}, status: :unprocessable_entity
    end
  end

  def set_balance
    # see the Rails - Step by step New Feature in the Notes programing file
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
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to cash_flows_path}
    end
  end

  private

  def cash_flow_params
    params.require(:cash_flow).permit(:date, :description, :amount)
  end

  def validate_csv(file)
    content_type = file.content_type
    if (content_type == 'text/csv')
      true
    else
      false
    end
  end

  def headers_match?(headers)
    headers.sort == CashFlow::EXPECTED_HEADERS.sort
  end

  def is_number?(string)
    true if Float(string) rescue false
  end
end
