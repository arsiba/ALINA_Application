class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :prevent_private_caching

  inertia_share flash: -> { flash.to_hash }, cookie_settings: -> { participation_cookies.settings }
  wrap_parameters false # Disable default wrapping of parameters in JSON requests (Helpful with Inertia js)

  private

  def participation_cookies
    @participation_cookies ||= ParticipationCookies.new(cookies, secure: request.ssl?)
  end

  def prevent_private_caching
    response.headers["Cache-Control"] = "no-store"
  end
end
