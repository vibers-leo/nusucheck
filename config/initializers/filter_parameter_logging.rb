# 로그에서 민감한 파라미터 마스킹
# Rails 기본값(password, secret 등)에 누수체크 도메인 특화 항목 추가
Rails.application.config.filter_parameters += %i[
  passw secret token _key salt certificate otp ssn
  card_number cvv billing_key
  toss_secret portone_secret codef_secret
  access_token refresh_token id_token
  phone email
]
