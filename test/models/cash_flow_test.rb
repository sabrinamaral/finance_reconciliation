require "test_helper"

class CashFlowTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    CashFlow.delete_all # Clear all records before each test
    @valid_csv = file_fixture("valid_cash_flows.csv").to_s
    @empty_csv = file_fixture("empty.csv").to_s
  end

  test "should import valid CSV and create records" do
    result = CashFlow.import_from_csv(@valid_csv, @user)
    assert result[:success], "Expected import to succeed"
    assert_equal 3, CashFlow.count, "Expected 3 cash flow records to be created"
  end

  test "should return error when a column is missing" do
    result = CashFlow.import_from_csv(file_fixture("cash_flows_missing_column.csv").to_s, @user)
    assert_not result[:success], "Expected import to fail"
    assert_equal CashFlow::COLUMNS_ERROR, result[:error]
    assert_equal 0, CashFlow.count, "Expected no records to be created"
  end

  test "should accept headers in any language" do
    result = CashFlow.import_from_csv(file_fixture("cash_flows_headers.csv").to_s, @user)
    assert result[:success], "Expected import to succeed"
    assert_equal 1, CashFlow.count
  end

  test "should reject an invalid transaction type" do
    result = CashFlow.import_from_csv(file_fixture("cash_flows_invalid_type.csv").to_s, @user)
    assert_not result[:success]
    assert_match(/Expected 'C' or 'D'/, result[:error])
    assert_equal 0, CashFlow.count
  end

  test "should handle empty CSV file gracefully" do
    result = CashFlow.import_from_csv(@empty_csv, @user)
    assert result[:success], "Expected import to succeed for empty file"
    assert_equal 0, CashFlow.count, "Expected no records to be created"
  end

  test "should not save any row when one row is invalid" do
    result = CashFlow.import_from_csv(file_fixture("cash_flows_invalid_row.csv").to_s, @user)
    assert_not result[:success], "Expected import to fail"
    assert_match(/row 3/, result[:error])
    assert_equal 0, CashFlow.count, "Expected the valid first row to be rolled back"
  end

end
