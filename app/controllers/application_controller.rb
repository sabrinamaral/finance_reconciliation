class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action do
    Current.user = current_user
  end
end
