require "test_helper"

class DevisePasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one) # Assuming you have a user fixture named :one
  end

  test "does not expose the public password reset request" do
    assert_no_emails do
      post user_password_path, params: { user: { email: @user.email } }
    end
    assert_response :not_found
  end


  test "should reset password with valid token" do
        raw_token = @user.send(:set_reset_password_token)

    put user_password_path, params: {
      user: {
        reset_password_token: raw_token,
        password: "newpassword",
        password_confirmation: "newpassword"
      }
    }

    assert_response :redirect
    follow_redirect!
    assert_match (/Your password has been changed successfully/), flash[:notice]
  end
end
