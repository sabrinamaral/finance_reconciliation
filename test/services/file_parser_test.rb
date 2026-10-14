require "test_helper"

class FileParserTest < ActiveSupport::TestCase
  # FileParser is a module, so the tests use a small class that includes it
  class Parser
    include FileParser
  end

  test "rejects a date column mixing real dates and text" do
    rows = [[Date.new(2025, 5, 4), "Converted by Excel"], ["15/04/2025", "Left as text"]]

    assert_raises(FileParser::MixedDateFormatsError) { check(rows) }
  end

  test "accepts a column with only real dates" do
    rows = [[Date.new(2025, 4, 5), "a"], [Date.new(2025, 4, 15), "b"]]

    assert_nothing_raised { check(rows) }
  end

  test "ignores blank cells" do
    rows = [[Date.new(2025, 4, 5), "a"], [nil, "b"], ["", "c"]]

    assert_nothing_raised { check(rows) }
  end

  private

  def check(rows)
    Parser.new.send(:check_date_column!, rows)
  end
end
