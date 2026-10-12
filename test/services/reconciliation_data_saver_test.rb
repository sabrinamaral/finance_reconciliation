require "test_helper"

class ReconciliationDataSaverTest < ActiveSupport::TestCase
  setup do
    Current.user = users(:one)
    @period = audit_periods(:one)
    @valid_file        = csv_upload("reconciliation_valid_file.csv")
    @invalid_date_file = csv_upload("invalid_date_file.csv")
  end

  test "saves valid data from both files" do
    service = build_service(@valid_file, @valid_file)

    assert_difference({ -> { FinanceRecord.count } => 3, -> { FinanceRecord2.count } => 3 }) do
      assert service.call[:success]
    end
  end

  test "returns an error and saves nothing if a record fails to save" do
    FinanceRecord.any_instance.stubs(:save).returns(false)
    service = build_service(@valid_file, @valid_file)

    assert_no_difference [-> { FinanceRecord.count }, -> { FinanceRecord2.count }] do
      result = service.call
      assert_not result[:success]
      assert_match(/Failed to save record/, result[:error])
    end
  end

  test "returns an error for invalid date format" do
    service = build_service(@invalid_date_file, @valid_file)

    assert_no_difference [-> { FinanceRecord.count }, -> { FinanceRecord2.count }] do
      result = service.call
      assert_not result[:success]
      assert_match(/Invalid date format \(row 1\)/, result[:error])
    end
  end

  test "rolls back the first file when the second file is invalid" do
    service = build_service(@valid_file, @invalid_date_file)

    assert_no_difference [-> { FinanceRecord.count }, -> { FinanceRecord2.count }] do
      assert_not service.call[:success]
    end
  end

  private

  def build_service(file1, file2)
    ReconciliationDataSaver.new(file1, file2, FinanceRecord, FinanceRecord2, @period)
  end

  def csv_upload(name)
    Rack::Test::UploadedFile.new(file_fixture(name), "text/csv")
  end
end
