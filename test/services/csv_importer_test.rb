require "test_helper"

class CsvImporterTest < ActiveSupport::TestCase
  test "parses Brazilian text amounts" do
    result = CsvImporter.parse_row(row("07/04/2025", "Pix", "R$ 3.000,50", "D"))
    assert_equal BigDecimal("-3000.50"), result.data[:amount]
  end

  test "parses numeric amounts from Excel" do
    result = CsvImporter.parse_row(row("07/04/2025", "Pix", 3000.5, "C"))
    assert_equal BigDecimal("3000.5"), result.data[:amount]
  end

  test "uses the entry type for the sign, not the file" do
    result = CsvImporter.parse_row(row("07/04/2025", "Pix", "-3.000,50", "D"))
    assert_equal BigDecimal("-3000.50"), result.data[:amount]
  end

  test "rejects blank amounts" do
    result = CsvImporter.parse_row(row("07/04/2025", "Pix", "", "D"))
    assert_not result.success
    assert_match(/Invalid amount/, result.error)
  end

  private

  def row(*fields)
    CSV::Row.new(%w[date description amount type], fields)
  end
end
