class ParticipationCookies
  STATUS_KEY = "alina_participated".freeze
  DAYS = 30

  def initialize(cookies, secure:)
    @cookies = cookies
    @secure = secure
  end

  def settings
    { participated: participated?, duration_days: DAYS }
  end

  def participated?
    @cookies[STATUS_KEY] == "1"
  end

  def mark_participated
    return if participated?

    @cookies[STATUS_KEY] = {
      value: "1", path: "/", expires: DAYS.days.from_now, max_age: DAYS.days.to_i,
      httponly: true, secure: @secure, same_site: :lax
    }
  end
end
