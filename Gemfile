source "https://rubygems.org"

ruby "~> 3.2"

gem "rails", "~> 7.1.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "redis", ">= 4.0.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"
gem "streamio-ffmpeg"

# Authentication & Authorization
gem "devise"
# 카카오 로그인 (OAuth2 기반 커스텀 전략)
gem "omniauth-oauth2", "~> 1.8"
gem "omniauth-rails_csrf_protection"
gem "pundit"

# State Machine
gem "aasm"

# PDF Generation
gem "prawn"
gem "prawn-table"
gem "matrix"  # Ruby 3.2+에서 기본 gem에서 제거됨 (prawn 의존성)

# Background Jobs
gem "sidekiq"
gem "sidekiq-cron", "~> 1.12"

# Error Tracking
gem "sentry-ruby"
gem "sentry-rails"
gem "sentry-sidekiq"

# Pagination & Search
gem "kaminari"
gem "ransack"

# Geocoding
gem "geocoder"

# JSON
gem "jbuilder"

# JWT (모바일 앱 API 인증)
gem "jwt"

# CORS (모바일 앱 API 요청 허용)
gem "rack-cors"

# Cloud Storage (Cloudflare R2 / Amazon S3 compatible)
gem "aws-sdk-s3", require: false

# AI (Claude Vision API)
gem "anthropic"

# CODEF API (금융 데이터 연동 - 보험 조회 등)
gem "easycodefrb"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end
