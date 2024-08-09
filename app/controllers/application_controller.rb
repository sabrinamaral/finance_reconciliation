class ApplicationController < ActionController::Base
  before_action :set_current_user, :required_user_logged_in!
  helper_method :user_signed_in?

  def set_current_user
    if session[:user_id]
      Current.user = User.find_by(id: session[:user_id])
    end
  end

  private

  def required_user_logged_in!
    redirect_to sign_in_path, alert: "You must be signed in to do that." if Current.user.nil?
  end

  def user_signed_in?
    set_current_user.present?
  end
end
