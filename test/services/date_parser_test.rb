require "test_helper"

class DateParserTest < ActiveSupport::TestCase
  test "should parse valid date in DD/MM/YYYY format" do
    assert_equal({:success => :success, :date => Date.new(2025, 4, 7)}, DateParser.parse("07/04/2025"))
  end
  test "should parse valid date in YYYY-MM-DD format" do
    assert_equal({ :success => :success, :date => Date.new(2025, 4, 7) }, DateParser.parse("2025-04-07"))
  end
  test "should parse valid date in DD-MM-YYYY format" do
    assert_equal({ :success => :success, :date => Date.new(2025, 4, 7) }, DateParser.parse("07-04-2025"))
  end

end
