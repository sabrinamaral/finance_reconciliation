require "test_helper"
require "minitest/mock"

class ReconciliationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Include Devise helpers

def setup
  @user = users(:one)
  sign_in @user
  # Access fixture data
  @finance_record1 = finance_records(:one)
  @finance_record2 = finance_record2s(:one)
  # Matching records
  @matching_record1 = FinanceRecord.create!(date: '2025-04-21', amount: 100, reconciled: false)
  @matching_record2 = FinanceRecord2.create!(date: '2025-04-21', amount: 100, reconciled: false)
  # Non-matching records
  @non_matching_record1 = FinanceRecord.create!(date: '2025-04-21', amount: 300, reconciled: false)
  @non_matching_record2 = FinanceRecord2.create!(date: '2025-04-22', amount: 300, reconciled: false)
  @invalid_content_type = Rack::Test::UploadedFile.new(file_fixture("invalid_format.txt"))
end

  test "should get new and initialize instance variables" do
    get new_reconciliation_path
    assert_response :success
    assert assigns(:file1).is_a?(FinanceRecord)
    assert assigns(:file2).is_a?(FinanceRecord2)
  end

  test "should get index and assign instance variables" do
    get reconciliations_path
    assert_response :success
    assert_equal FinanceRecord.all, assigns(:csv_data1)
    assert_equal FinanceRecord2.all, assigns(:csv_data2)
  end

  test "reconciles matching records correctly" do
    controller = ReconciliationsController.new
    controller.send(:match, FinanceRecord.all, FinanceRecord2.all)

    assert @matching_record1.reload.reconciled, "Matching record 1 should be reconciled"
    assert @matching_record2.reload.reconciled, "Matching record 2 should be reconciled"

    refute @non_matching_record1.reload.reconciled, "Non-matching record 1 should not be reconciled"
    refute @non_matching_record2.reload.reconciled, "Non-matching record 2 should not be reconciled"
  end

  test "should not proceed without both CSV files" do
    post reconciliations_path, params: { file1: nil, file2: nil }
    assert_response :unprocessable_entity
    assert_equal "Please upload both files", flash[:alert]
  end

  test "should reject invalid content type" do
    post reconciliations_path, params: { file1: @invalid_content_type, file2: @invalid_content_type}
    assert_response :unprocessable_entity
    assert_equal "Please upload CSV files only", flash[:alert]
  end

  test "should delete all transactions from reconciliation" do
    delete delete_all_reconciliations_path
    assert_redirected_to root_path
    assert_equal 0, FinanceRecord.count
    assert_equal 0, FinanceRecord2.count
  end

  test "should generate PDF successfully" do
    get  download_pdf_reconciliations_path
    assert_response :success
    assert_equal "application/pdf", @response.content_type
  end

  test "PDF should contain expected content" do
    get download_pdf_reconciliations_path
    assert_response :success

    # check that the response body has expected text
    pdf_text = PDF::Reader.new(StringIO.new(@response.body)).pages.map(&:text).join(" ")
    assert_includes pdf_text, "Date"
    assert_includes pdf_text, "Description"
    assert_includes pdf_text, "Amount"
  end
end
