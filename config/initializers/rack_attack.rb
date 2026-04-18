# frozen_string_literal: true

class Rack::Attack
  ### Safelist — 내부 헬스체크/로컬 개발 허용 ###
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### Throttle — 로그인 브루트포스 방지 ###
  # IP당 분당 5회 (잠금 전 경고)
  throttle("login/ip", limit: 5, period: 60) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # 이메일당 10분에 10회
  throttle("login/email", limit: 10, period: 600) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  ### Throttle — 회원가입 스팸 방지 ###
  throttle("signup/ip", limit: 5, period: 3600) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  ### Throttle — 비밀번호 재설정 ###
  throttle("password_reset/ip", limit: 5, period: 3600) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  ### Throttle — 일반 API 요청 ###
  # IP당 분당 120회 (정상 사용 허용, 스크래핑 방지)
  throttle("api/ip", limit: 120, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  ### Blocklist — 명백한 공격 패턴 ###
  blocklist("block-bad-agents") do |req|
    ua = req.user_agent.to_s.downcase
    ua.include?("sqlmap") || ua.include?("nikto") || ua.include?("masscan")
  end

  ### 응답 커스터마이징 ###
  self.throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "요청이 너무 많아요. 잠시 후 다시 시도해 주세요." }.to_json]
    ]
  end
end

# 개발 환경에서는 Rack::Attack 비활성화 (로컬 개발 방해 방지)
Rails.application.config.middleware.use Rack::Attack unless Rails.env.test?
