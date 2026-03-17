Devise.setup do |config|
  config.mailer_sender = ENV.fetch("SMTP_USERNAME", "noreply@nusucheck.kr")
  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true

  # 로그인 유지 기간 설정 (1년)
  config.remember_for = 1.year

  # 사용자가 사이트 방문 시 remember me 쿠키 자동 갱신
  config.extend_remember_period = true

  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.navigational_formats = ["*/*", :html, :turbo_stream]

  # OmniAuth 설정 (카카오 로그인) - 나중에 추가 예정
  # if ENV['KAKAO_CLIENT_ID'].present?
  #   config.omniauth :kakao,
  #     ENV['KAKAO_CLIENT_ID'],
  #     scope: 'profile_nickname,account_email'
  # end
end
