require "test_helper"

class CashFlowsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get cash_flows_create_url
    assert_response :success
  end
end
