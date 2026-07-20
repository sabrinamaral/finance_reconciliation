class AuditPeriodsController < ApplicationController
  def create
    @audit  = Audit.find_by(user_id: Current.user.id)
    @period = @audit.audit_periods.new(period_params)

    if @period.save
      redirect_to reconciliations_path(period_id: @period.id),
                  notice: "Period #{@period.label} created successfully."
    else
      redirect_to reconciliations_path,
                  alert: @period.errors.full_messages.join(", ")
    end
  end

  private

  def period_params
    params.require(:audit_period).permit(:month, :year)
  end
end
