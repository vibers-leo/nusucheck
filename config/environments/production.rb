require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.assets.compile = false
  # 스토리지 우선순위: OCI > R2 > 로컬 디스크
  config.active_storage.service = if ENV["OCI_ENDPOINT"].present?
    :oracle_cloud
  elsif ENV["R2_ENDPOINT"].present?
    :cloudflare_r2
  else
    :local
  end
  config.force_ssl = true
  # /up 헬스체크는 SSL 리디렉션에서 제외 (Fly.io 내부 HTTP 체크용)
  config.ssl_options = { redirect: { exclude: -> request { request.path == "/up" } } }
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # 허용 호스트 설정
  config.hosts = [
    "nusucheck.com",
    "www.nusucheck.com",
    "expert.nusucheck.com",
    "app.nusucheck.com",
    "nusucheck.fly.dev",
    /.*\.nusucheck\.com/,  # 모든 서브도메인 허용
    /\A[\d.]+\z/,          # Fly.io 헬스체크용 내부 IP 허용 (172.x.x.x)
    /\A[\d.]+:\d+\z/,      # IP:port 형식 허용 (172.x.x.x:3000)
    /\A[0-9a-f:]+\z/       # IPv6 허용
  ]

  # Action Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "nusucheck.com", protocol: "https" }
  config.action_mailer.delivery_method = ENV.fetch("MAILER_DELIVERY_METHOD", "smtp").to_sym
  config.action_mailer.smtp_settings = {
    # Resend.com: SMTP_ADDRESS=smtp.resend.com, SMTP_USERNAME=resend, SMTP_PASSWORD=API_KEY
    # Gmail: SMTP_ADDRESS=smtp.gmail.com, SMTP_USERNAME=email, SMTP_PASSWORD=앱비밀번호
    address:              ENV.fetch("SMTP_ADDRESS", "smtp.resend.com"),
    port:                 ENV.fetch("SMTP_PORT", 587).to_i,
    domain:               "nusucheck.com",
    user_name:            ENV.fetch("SMTP_USERNAME", "resend"),
    password:             ENV["SMTP_PASSWORD"],
    authentication:       "plain",
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
