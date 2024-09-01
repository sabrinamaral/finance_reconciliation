class CashFlowsController < ApplicationController
  def new
    @cash_flow_records = CashFlow.all
  end


  def create
    unless params[:cash_flow].present? && params[:cash_flow][:file].present?
      flash.now[:alert] = 'Please upload a file.'
      render 'reconciliations/new', status: :unprocessable_entity
      return
    end

    @csv_file = params[:cash_flow][:file]

    if validate_csv(@csv_file)
      CashFlow.import_from_csv(@csv_file)
      redirect_to cash_flows_path, notice: 'Cash flow records are successfully created.'
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

  private

  def cash_flow_params
    params.require(:cash_flow).permit(:date, :description, :amount)
  end

  def validate_csv(file)
    content_type = file.content_type
    if (content_type == 'text/csv')
      true
    else
      flash.now[:alert] = 'Please upload CSV files only.'
      render 'reconciliations/new', status: :unprocessable_entity
      false
    end
  end
end
