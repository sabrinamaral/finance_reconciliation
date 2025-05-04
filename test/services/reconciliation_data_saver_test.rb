require "test_helper"

class ReconciliationDataSaverTest < ActiveSupport::TestCase
  def setup
    @valid_file = file_fixture("reconciliation_valid_file.csv")
    @invalid_date_file = file_fixture("invalid_date_file.csv")
    @model_1 = FinanceRecord
    @model_2 = FinanceRecord2

    # Clear the database before each test
    @model_1.delete_all
    @model_2.delete_all
  end

  test "should save valid data to the database" do
    service = ReconciliationDataSaver.new(@valid_file, @valid_file, @model_1, @model_2)
    result = service.call

    assert result[:success]
    assert_equal 3, @model_1.count
  end

  test "should return an error if record fails to save" do
    @model_1.any_instance.stubs(:save).returns(false) do
      service = ReconciliationDataSaver.new(@valid_file, @model_1)
      result = service.call

      assert_not result[:success]
      assert_match(/Failed to save record/, result[:error])
    end
  end

    test "should return an error for invalid date format" do
      service = ReconciliationDataSaver.new( @invalid_date_file, @invalid_date_file, @model_1, @model_2)
      result = service.call

      assert_not result[:success]
      assert_equal 0, @model_1.count
    end
end
