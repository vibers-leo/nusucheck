# 카카오 OAuth2 전략 (Zeitwerk 오토로딩 충돌 방지를 위해 여기서 정의)
require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Kakao < OmniAuth::Strategies::OAuth2
      option :name, "kakao"

      option :client_options, {
        site: "https://kauth.kakao.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token"
      }

      uid { raw_info["id"].to_s }

      info do
        {
          name: kakao_account.dig("profile", "nickname"),
          email: kakao_account["email"],
          image: kakao_account.dig("profile", "profile_image_url"),
          nickname: kakao_account.dig("profile", "nickname")
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get(
          "https://kapi.kakao.com/v2/user/me",
          headers: { "Content-Type" => "application/x-www-form-urlencoded;charset=utf-8" }
        ).parsed
      end

      private

      def kakao_account
        raw_info.fetch("kakao_account", {})
      end

      def callback_url
        full_host + callback_path
      end
    end
  end
end

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

  # OmniAuth 설정 (카카오 로그인)
  if ENV['KAKAO_CLIENT_ID'].present?
    config.omniauth :kakao,
      ENV['KAKAO_CLIENT_ID'],
      ENV.fetch('KAKAO_CLIENT_SECRET', ''),
      scope: 'profile_nickname,account_email',
      strategy_class: OmniAuth::Strategies::Kakao
  end
end
