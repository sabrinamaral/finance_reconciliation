require "test_helper"

class ReconciliationCsvFileValidatorTest < ActiveSupport::TestCase
  test "accepts files with a single data row" do
    file = csv_upload("single_row.csv")
    result = ReconciliationCsvFileValidator.new(file, file).validate

    assert result[:success], result[:error]
  end

  test "rejects files with only headers" do
    file = csv_upload("empty.csv")
    result = ReconciliationCsvFileValidator.new(file, file).validate

    assert_not result[:success]
    assert_equal "One or both files have no data rows.", result[:error]
  end

  private

  def csv_upload(name)
    Rack::Test::UploadedFile.new(file_fixture(name), "text/csv")
  end
end
