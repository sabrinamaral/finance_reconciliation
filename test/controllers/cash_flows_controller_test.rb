require "test_helper"

class CashFlowsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:one)
    sign_in @user
    @cash_flow = CashFlow.create!(date: "2025-04-01", description: "Test", amount: 100, transaction_type: 0)
    @valid_csv = file_fixture("valid_cash_flows.csv")
    @invalid_csv = file_fixture("invalid_headers.csv")
  end

  # test "should get index" do
  #   get cash_flows_path
  #   assert_response :success
  #   assert_not_nil assigns(:cash_flow_records)
  # end

  # test "should get new" do
  #   get new_cash_flow_path
  #   assert_response :success
  # end

  # test "should create cash flows from valid CSV" do
  #   post cash_flows_path, params: { cash_flow: { file: @valid_csv } }
  #   assert_redirected_to cash_flows_path
  #   assert_equal "Cash flow records are successfully created.", flash[:notice]
  # end

  # test "should not create cash flows from invalid CSV" do
  #   post cash_flows_path, params: { cash_flow: { file: @invalid_csv } }
  #   assert_redirected_to cash_flows_path
  #   assert_equal "CSV headers must be: date, description, amount, transaction_type", flash[:alert]
  # end

  # test "should not create cash flows without file" do
  #   post cash_flows_path, params: { cash_flow: {} }
  #   assert_response :unprocessable_entity
  #   assert_equal "Please upload a CSV file.", flash[:alert]
  # end

  # test "should get edit" do
  #   get edit_cash_flow_path(@cash_flow)
  #   assert_response :success
  # end

  # test "should update cash flow" do
  #   patch cash_flow_path(@cash_flow), params: { cash_flow: { description: "Updated Description" } }
  #   assert_redirected_to cash_flows_path
  #   assert_equal "Updated Description", @cash_flow.reload.description
  # end

  # test "should not update cash flow with invalid data" do
  #   patch cash_flow_path(@cash_flow), params: { cash_flow: { amount: nil } }
  #   assert_response :success
  #   assert_template :index
  # end

  # test "should destroy cash flow" do
  #   assert_difference("CashFlow.count", -1) do
  #     delete cash_flow_path(@cash_flow)
  #   end
  #   assert_response :success
  # end

  # test "should delete all cash flows" do
  #   delete delete_all_cash_flows_path
  #   assert_redirected_to cash_flows_path
  #   assert_equal "All records have been deleted.", flash[:notice]
  #   assert_equal 0, CashFlow.count
  # end

  # test "should set balance" do
  #   post set_balance_cash_flows_path, params: { starting_balance: 1000 }
  #   assert_response :success
  #   assert_equal "1000", session[:starting_balance]
  # end

  # test "should not set invalid balance" do
  #   post set_balance_cash_flows_path, params: { starting_balance: "invalid" }
  #   assert_response :unprocessable_entity
  #   assert_equal "Balance must be a valid number.", JSON.parse(@response.body)["message"]
  # end

  # test "should reset balance" do
  #   session[:starting_balance] = 1000
  #   post reset_balance_cash_flows_path
  #   assert_redirected_to cash_flows_path
  #   assert_equal 0, session[:starting_balance]
  # end
end
