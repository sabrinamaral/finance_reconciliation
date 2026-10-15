require "test_helper"

class DateParserTest < ActiveSupport::TestCase
  test "should parse valid date in DD/MM/YYYY format" do
    assert_equal({:success => :success, :date => Date.new(2025, 4, 7)}, DateParser.parse("07/04/2025"))
  end
  test "should parse valid date in DD/MM/YY format" do
    assert_equal({ :success => :success, :date => Date.new(2025, 4, 7) }, DateParser.parse("07/04/25"))
  end
  test "should parse valid date in DD-MM-YYYY format" do
    assert_equal({ :success => :success, :date => Date.new(2025, 4, 7) }, DateParser.parse("07-04-2025"))
  end
  test "should parse valid date in DD-MM-YY format" do
    assert_equal({ :success => :success, :date => Date.new(2025, 4, 7) }, DateParser.parse("07-04-25"))
  end

  test "detects DD/MM when a first number is above 12" do
    assert_equal :dmy, DateParser.detect_order(["05/04/2025", "15/04/2025"])
  end

  test "detects MM/DD when a second number is above 12" do
    assert_equal :mdy, DateParser.detect_order(["04/05/2025", "04/15/2025"])
  end

  test "defaults to DD/MM when all dates are ambiguous" do
    assert_equal :dmy, DateParser.detect_order(["01/04/2025", "12/04/2025"])
  end

  test "returns conflict when both orders appear" do
    assert_equal :conflict, DateParser.detect_order(["15/04/2025", "04/15/2025"])
  end

  test "ignores blank and year-first values when detecting" do
    assert_equal :mdy, DateParser.detect_order([nil, "", "2025-04-15", "04/15/2025"])
  end

  test "reads the same ambiguous text according to the order" do
    assert_equal Date.new(2025, 4, 5), DateParser.parse("05/04/2025")[:date]
    assert_equal Date.new(2025, 5, 4), DateParser.parse("05/04/2025", order: :mdy)[:date]
  end
end
