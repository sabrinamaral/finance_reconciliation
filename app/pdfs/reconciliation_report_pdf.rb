require "prawn/table"

# Builds the reconciliation PDF reports (bank statement vs. system, receipts, invoices).
#
# Usage:
#   ReconciliationReportPdf.new(
#     title: "Invoices Reconciliation Report — July/2026",
#     sections: [
#       { title: "Bank Statement", records: @bank_records, checked: ->(r) { r.invoice_match&.checked } },
#       { title: "Invoices",       records: @invoice_data, checked: ->(r) { r.checked } }
#     ]
#   ).render
class ReconciliationReportPdf
  include Prawn::View

  HEADER_BG    = "E9ECEF"
  BORDER_COLOR = "CCCCCC"
  DEBIT_COLOR  = "C0392B"
  CREDIT_COLOR = "2E86C1"
  FONT_DIR = Rails.root.join("vendor/fonts")

  def initialize(title:, sections:)
    @title    = title
    @sections = sections
    build
  end

  # Prawn::View delegates drawing methods (text, table, move_down...) to this document
  def document
    @document ||= Prawn::Document.new(page_size: "A4", margin: 28).tap do |doc| # 28pt ≈ 1cm
      doc.font_families.update(
        "DejaVuSans" => {
          normal: FONT_DIR.join("DejaVuSans.ttf").to_s,
          bold:   FONT_DIR.join("DejaVuSans-Bold.ttf").to_s,
          italic: FONT_DIR.join("DejaVuSans-Oblique.ttf").to_s
        }
      )
      doc.font "DejaVuSans"
    end
  end

  private

  def build
    font_size 8.5
    text @title, size: 14, style: :bold
    move_down 12

    @sections.each { |section| render_section(section) }
  end

  def render_section(section)
    text section[:title], size: 11, style: :bold
    move_down 6

    if section[:records].empty?
      text "No records.", style: :italic
    else
      table(table_rows(section),
            header: true,
            width: bounds.width,
            column_widths: { 0 => 55, 2 => 90, 3 => 55 },
            cell_style: { border_color: BORDER_COLOR, border_width: 0.5, padding: [3, 6] }) do |t|
        t.row(0).background_color = HEADER_BG
        t.row(0).font_style       = :bold
      end
    end

    move_down 18
  end

  def table_rows(section)
    header = ["Date", "Description", "Amount", "Checked"]

    rows = section[:records].map do |record|
      [
        record.date&.strftime("%d/%m/%y").to_s,
        record.description.to_s,
        amount_cell(record.amount),
        section[:checked].call(record) ? "Yes" : "No"
      ]
    end

    [header, *rows]
  end

  def amount_cell(amount)
    formatted = ActiveSupport::NumberHelper.number_to_currency(
      amount.abs, unit: "R$ ", separator: ",", delimiter: ".", precision: 2
    )

    {
      content:    "#{amount.negative? ? '- ' : '+ '}#{formatted}",
      text_color: amount.negative? ? DEBIT_COLOR : CREDIT_COLOR
    }
  end
end
