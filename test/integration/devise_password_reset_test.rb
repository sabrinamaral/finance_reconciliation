require "test_helper"

class DevisePasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one) # Assuming you have a user fixture named :one
  end

  test "should send password reset email" do
    post user_password_path, params: { user: { email: @user.email } }
    assert_response :redirect
    follow_redirect!
    assert_match (/You will receive an email with instructions on how to reset your password in a few minutes./), flash[:notice]
  end

  test "should reset password with valid token" do
    raw_token = @user.send_reset_password_instructions

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
