require "test_helper"

class AuditPeriodTest < ActiveSupport::TestCase
  test "destroy_with_records! deletes the period and all its records" do
    period = audit_periods(:one)

    period.destroy_with_records!

    assert_not AuditPeriod.exists?(period.id)
    [FinanceRecord, FinanceRecord2, FinanceRecord3, FinanceRecord4].each do |model|
      assert_not model.exists?(audit_period_id: period.id), "#{model} records should be deleted"
    end
  end

  test "destroy_with_records! keeps other periods intact" do
    audit_periods(:one).destroy_with_records!

    assert AuditPeriod.exists?(audit_periods(:two).id)
    assert FinanceRecord3.exists?(audit_period: audit_periods(:two))
  end

  test "destroy_with_records! removes matches pointing to its receipts and invoices" do
    # receipt_matches(:two) links a bank record of period one to a receipt of period two
    receipt_match_id = receipt_matches(:two).id
    invoice_match_id = invoice_matches(:two).id

    audit_periods(:two).destroy_with_records!

    assert_not ReceiptMatch.exists?(receipt_match_id)
    assert_not InvoiceMatch.exists?(invoice_match_id)
  end

end
