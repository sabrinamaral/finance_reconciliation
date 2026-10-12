class Users::SessionsController < Devise::SessionsController
  # Per IP: slows down attackers trying many accounts/passwords
  rate_limit to: 10, within: 3.minutes, only: :create, name: "login_by_ip",
            with: -> { too_many_attempts }

  # Per email: protects a specific account even if the attacker changes IP
  rate_limit to: 5, within: 10.minutes, only: :create, name: "login_by_email",
            by: -> { params.dig(:user, :email).to_s.strip.downcase },
            with: -> { too_many_attempts }

  private

  def too_many_attempts
    redirect_to new_user_session_path,
                alert: "Too many login attempts. Please try again in a few minutes."
  end
end
