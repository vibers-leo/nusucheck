# Content Security Policy
# https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "blob:"
    policy.object_src  :none

    # 스크립트: self + 사용 중인 CDN
    policy.script_src(
      :self,
      "https://js.tosspayments.com",   # 토스페이먼츠 SDK
      "https://cdn.jsdelivr.net",      # Driver.js, Chart.js
      "https://www.youtube.com",       # 유튜브 embed (전문가 프로필)
      :unsafe_inline                   # Turbo/Stimulus inline 핸들러 (추후 nonce로 전환)
    )

    # 스타일: self + CDN
    policy.style_src(
      :self,
      "https://cdn.jsdelivr.net",
      :unsafe_inline                   # Tailwind 인라인 스타일
    )

    # Frame: 유튜브 embed만 허용
    policy.frame_src(
      :self,
      "https://www.youtube.com",
      "https://youtube.com",
      "https://js.tosspayments.com"    # 토스 결제창
    )

    # WebSocket (ActionCable)
    policy.connect_src(
      :self,
      "wss://nusucheck.com",
      "wss://www.nusucheck.com",
      "wss://nusucheck.vibers.co.kr",
      "https://js.tosspayments.com",
      "https://sentry.io"              # Sentry 에러 리포트
    )

    policy.worker_src :blob, :self
  end

  # Nonce 생성 (향후 unsafe_inline 제거 시 사용)
  # config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report-Only 모드: 위반 차단 없이 로그만 수집 (첫 배포 시 안전)
  config.content_security_policy_report_only = true
end
