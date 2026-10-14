require "test_helper"

class AuditPeriodsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)
  end

  test "deletes the user's own period" do
    period = audit_periods(:one)

    delete audit_period_path(period)

    assert_redirected_to reconciliations_path
    assert_not AuditPeriod.exists?(period.id)
  end

  test "does not delete another user's period" do
    period = audit_periods(:two) # belongs to users(:two)

    delete audit_period_path(period)

    assert_response :not_found
    assert AuditPeriod.exists?(period.id)
  end
end
