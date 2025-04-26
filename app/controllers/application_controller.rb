class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :authenticate_user!

  layout :layout_by_resource

  private

  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end
end
