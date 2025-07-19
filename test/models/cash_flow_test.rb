require "test_helper"

class CashFlowTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    CashFlow.delete_all # Clear all records before each test
    @valid_csv = file_fixture("valid_cash_flows.csv").to_s
    @invalid_headers_csv = file_fixture("invalid_headers.csv").to_s
    @empty_csv = file_fixture("empty.csv").to_s
  end

  test "should import valid CSV and create records" do
    result = CashFlow.import_from_csv(@valid_csv, @user)
    assert result[:success], "Expected import to succeed"
    assert_equal 3, CashFlow.count, "Expected 3 cash flow records to be created"
  end

  test "should return error for invalid CSV headers" do
    result = CashFlow.import_from_csv(@invalid_headers_csv, @user)
    assert_not result[:success], "Expected import to fail"
    assert_match(/(date, description, amount, transaction_type)/, result[:error], "Expected headers to be: date, description, amount and transaction_type, in this order")
    assert_equal 0, CashFlow.count, "Expected no records to be created"
  end

  test "should handle empty CSV file gracefully" do
    result = CashFlow.import_from_csv(@empty_csv, @user)
    assert result[:success], "Expected import to succeed for empty file"
    assert_equal 0, CashFlow.count, "Expected no records to be created"
  end
end
