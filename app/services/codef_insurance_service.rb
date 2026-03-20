# CODEF API를 통한 손해보험협회 배상책임보험 조회 서비스
#
# 플로우:
#   1. request_auth(user_info) → PASS/카카오 간편인증 요청 → 휴대폰 알림 발생
#   2. (사용자가 휴대폰에서 인증 승인)
#   3. poll_result(job_id) → 인증 완료 확인 → 보험 목록 반환
#
# 환경변수: CODEF_CLIENT_ID, CODEF_CLIENT_SECRET, CODEF_PUBLIC_KEY

require "base64"
require "net/http"
require "json"
require "openssl"

class CodefInsuranceService
  # 간편인증 loginType 코드
  LOGIN_TYPES = {
    pass:   "5",  # PASS 앱 (SKT/KT/LGU 통신사 인증)
    kakao:  "4",  # 카카오 간편인증
    naver:  "6"   # 네이버 간편인증
  }.freeze

  # 통신사 코드
  TELECOM_CODES = {
    "SKT" => "1",
    "KT"  => "2",
    "LGU" => "3",
    "SKT알뜰폰" => "4",
    "KT알뜰폰"  => "5",
    "LGU알뜰폰" => "6"
  }.freeze

  attr_reader :error_message

  def initialize
    @client_id     = ENV["CODEF_CLIENT_ID"]
    @client_secret = ENV["CODEF_CLIENT_SECRET"]
    @public_key    = ENV["CODEF_PUBLIC_KEY"]
  end

  def configured?
    CodefConfig.configured?
  end

  # Step 1: 간편인증 요청 (사용자 휴대폰으로 PASS 알림 발송)
  # user_info: { name:, birth: "YYYYMMDD", phone:, telecom: "SKT"|"KT"|"LGU", login_type: :pass }
  # 반환: { success: true, job_id: "...", message: "..." } 또는 { success: false, error: "..." }
  def request_auth(user_info)
    return sandbox_auth_response if CodefConfig.sandbox_mode?
    return not_configured unless configured?

    token = fetch_token
    return not_configured unless token

    login_type = LOGIN_TYPES[user_info[:login_type]&.to_sym] || LOGIN_TYPES[:pass]

    body = {
      organization: "0020",      # 손해보험협회
      loginType: login_type,
      userName: user_info[:name],
      birthDate: user_info[:birth],
      phoneNo: user_info[:phone]&.gsub(/[^0-9]/, ""),
      telecom: TELECOM_CODES[user_info[:telecom]] || "1"
    }

    # PASS/카카오 방식은 비밀번호 불필요하지만 빈값 암호화 전송
    if @public_key.present?
      body[:password] = encrypt_rsa("")
    end

    response = post_api(CodefConfig::INSURANCE_LIST_URL, body, token)

    if response["code"] == "CF-00000"
      # 즉시 성공 (sandbox 또는 첫 응답)
      { success: true, done: true, contracts: parse_contracts(response["data"]) }
    elsif response["code"]&.start_with?("CF-03")
      # 간편인증 대기 상태 (사용자 휴대폰 승인 필요)
      job_id = response.dig("data", "jobId") || response.dig("result", "jobId")
      {
        success: true,
        done: false,
        job_id: job_id,
        message: response["message"] || "휴대폰에서 인증을 완료해주세요"
      }
    else
      { success: false, error: response["message"] || "인증 요청에 실패했어요" }
    end
  rescue => e
    Rails.logger.error("[CodefInsuranceService] request_auth 오류: #{e.message}")
    { success: false, error: "서비스 연결에 실패했어요" }
  end

  # Step 2: 인증 결과 폴링 (간편인증 승인 후 호출)
  # 반환: { success: true, done: true, contracts: [...] } 또는 done: false (아직 대기 중)
  def poll_result(job_id, user_info)
    return sandbox_poll_response if job_id == "SANDBOX-JOB-001"
    return not_configured unless configured?

    token = fetch_token
    return not_configured unless token

    body = {
      organization: "0020",
      jobId: job_id,
      userName: user_info[:name],
      birthDate: user_info[:birth],
      phoneNo: user_info[:phone]&.gsub(/[^0-9]/, "")
    }

    response = post_api(CodefConfig::INSURANCE_LIST_URL, body, token)

    if response["code"] == "CF-00000"
      { success: true, done: true, contracts: parse_contracts(response["data"]) }
    elsif response["code"]&.include?("CF-03")
      { success: true, done: false, message: "아직 인증 대기 중이에요" }
    else
      { success: false, error: response["message"] || "조회에 실패했어요" }
    end
  rescue => e
    Rails.logger.error("[CodefInsuranceService] poll_result 오류: #{e.message}")
    { success: false, error: "결과 조회 중 오류가 발생했어요" }
  end

  private

  def fetch_token
    uri = URI(CodefConfig::TOKEN_URL)
    req = Net::HTTP::Post.new(uri)

    credentials = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
    req["Authorization"] = "Basic #{credentials}"
    req["Content-Type"] = "application/x-www-form-urlencoded"
    req.body = "grant_type=client_credentials&scope=read"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(req)

    JSON.parse(response.body)["access_token"]
  rescue => e
    Rails.logger.error("[CodefInsuranceService] 토큰 발급 실패: #{e.message}")
    nil
  end

  def post_api(path, body, token)
    base_url = CodefConfig.api_url
    uri = URI("#{base_url}#{path}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req.body = body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    response = http.request(req)
    JSON.parse(response.body)
  end

  # RSA 공개키로 비밀번호 암호화 (CODEF 요구사항)
  def encrypt_rsa(plaintext)
    return "" if @public_key.blank?
    pem = "-----BEGIN PUBLIC KEY-----\n#{@public_key}\n-----END PUBLIC KEY-----"
    key = OpenSSL::PKey::RSA.new(pem)
    Base64.strict_encode64(key.public_encrypt(plaintext, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING))
  rescue => e
    Rails.logger.warn("[CodefInsuranceService] RSA 암호화 실패: #{e.message}")
    ""
  end

  # 보험 계약 목록에서 배상책임보험 필터링
  def parse_contracts(data)
    return [] if data.blank?

    list = data.is_a?(Array) ? data : (data["list"] || data["resCertifList"] || [])
    list.map do |c|
      {
        insurer_name:    c["resInsuranceName"] || c["insuranceCompanyName"],
        product_name:    c["resProdName"] || c["productName"],
        contract_no:     c["resContractNo"] || c["contractNumber"],
        valid_from:      parse_date(c["resContractStartDate"] || c["startDate"]),
        valid_until:     parse_date(c["resContractEndDate"] || c["maturityDate"] || c["expiredDate"]),
        has_liability:   liability_coverage?(c),
        status:          c["resContractStatus"] || c["contractStatus"]
      }
    end
  end

  def liability_coverage?(contract)
    fields = [
      contract["resProdName"], contract["productName"],
      contract["resInsuranceType"], contract["resContractDetail"]
    ].join(" ")
    %w[배상책임 일상배상 대인배상 신체배상].any? { |kw| fields.include?(kw) }
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str.to_s.gsub(/[^0-9]/, "").then { |s| "#{s[0..3]}-#{s[4..5]}-#{s[6..7]}" }) rescue nil
  end

  def not_configured
    { success: false, error: "CODEF API가 설정되지 않았어요" }
  end

  # ── 샌드박스(더미) 응답 ─────────────────────────────────────
  # request_auth 더미: done:false → waiting 화면 → poll 흐름을 전부 테스트 가능
  def sandbox_auth_response
    {
      success: true,
      done: false,
      job_id: "SANDBOX-JOB-001",
      message: "[테스트 모드] 인증 요청 전송됨 (자동으로 완료됩니다)"
    }
  end

  # poll 더미: 삼성화재 배상책임보험 + 현대해상 실손 2건 반환
  def sandbox_poll_response
    {
      success: true,
      done: true,
      contracts: [
        {
          insurer_name:  "삼성화재",
          product_name:  "일상생활배상책임보험",
          contract_no:   "SANDBOX-2024-001234",
          valid_from:    Date.current - 6.months,
          valid_until:   Date.current + 6.months,
          has_liability: true,
          status:        "정상"
        },
        {
          insurer_name:  "현대해상",
          product_name:  "실손의료비보험",
          contract_no:   "SANDBOX-2024-005678",
          valid_from:    Date.current - 1.year,
          valid_until:   Date.current + 1.year,
          has_liability: false,
          status:        "정상"
        }
      ]
    }
  end
end
