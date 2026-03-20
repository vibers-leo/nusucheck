# NAVER CLOVA OCR를 사용해 보험가입증명서를 자동 파싱하는 서비스
# 환경변수: NAVER_OCR_SECRET, NAVER_OCR_INVOKE_URL
require "net/http"
require "uri"
require "json"

class InsuranceOcrService
  def initialize(image_url)
    @image_url = image_url
  end

  def call
    return fallback_result("OCR 서비스가 설정되지 않았어요") unless configured?

    uri = URI(ENV["NAVER_OCR_INVOKE_URL"])
    req = Net::HTTP::Post.new(uri)
    req["X-OCR-SECRET"] = ENV["NAVER_OCR_SECRET"]
    req["Content-Type"] = "application/json"
    req.body = {
      version: "V2",
      requestId: SecureRandom.uuid,
      timestamp: (Time.current.to_f * 1000).to_i,
      lang: "ko",
      images: [{ format: detect_format(@image_url), name: "insurance_cert", url: @image_url }]
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    response = http.request(req)

    parse_response(JSON.parse(response.body))
  rescue => e
    Rails.logger.error("[InsuranceOcrService] OCR 오류: #{e.message}")
    fallback_result("OCR 처리 중 오류가 발생했어요")
  end

  def self.configured?
    ENV["NAVER_OCR_SECRET"].present? && ENV["NAVER_OCR_INVOKE_URL"].present?
  end

  private

  def configured?
    self.class.configured?
  end

  def detect_format(url)
    ext = File.extname(url.to_s).downcase.delete(".")
    %w[jpg jpeg png pdf tiff].include?(ext) ? (ext == "jpg" ? "jpeg" : ext) : "jpeg"
  end

  def parse_response(data)
    fields = data.dig("images", 0, "fields") || []
    all_text = fields.map { |f| f["inferText"].to_s }.join(" ")

    insurer_name  = extract_insurer(all_text, fields)
    valid_until   = extract_valid_until(all_text, fields)
    insured_name  = extract_insured_name(all_text, fields)
    has_liability = detect_liability_coverage(all_text)

    {
      success: true,
      insurer_name: insurer_name,
      valid_until: valid_until,
      insured_name: insured_name,
      has_liability_coverage: has_liability,
      raw_text: all_text.truncate(500),
      ocr_confidence: calculate_confidence(insurer_name, valid_until, insured_name)
    }
  end

  def extract_insurer(text, fields)
    insurers = %w[삼성화재 현대해상 DB손해보험 KB손해보험 메리츠화재 한화손해보험 롯데손해보험 흥국화재 농협손해보험 AXA악사 캐롯손해보험]
    found = insurers.find { |ins| text.include?(ins) }
    return found if found

    # "보험사:", "보험회사:" 패턴 추출
    if (m = text.match(/보험(?:사|회사)\s*[:：]?\s*([가-힣A-Za-z]{2,10}(?:화재|손해보험|생명)?)/))
      m[1]
    end
  end

  def extract_valid_until(text, fields)
    # "만기일", "보험기간", "유효기간" 다음에 오는 날짜 패턴
    patterns = [
      /(?:만기일|만기)\s*[:：]?\s*(\d{4})[.\-년](\d{1,2})[.\-월](\d{1,2})/,
      /(?:보험기간|유효기간).*?~\s*(\d{4})[.\-](\d{1,2})[.\-](\d{1,2})/,
      /(\d{4})[.\-](\d{2})[.\-](\d{2})\s*까지/
    ]

    patterns.each do |pat|
      if (m = text.match(pat))
        return Date.new(m[1].to_i, m[2].to_i, m[3].to_i) rescue nil
      end
    end
    nil
  end

  def extract_insured_name(text, fields)
    if (m = text.match(/(?:피보험자|보험계약자)\s*[:：]?\s*([가-힣]{2,5})/))
      m[1]
    end
  end

  def detect_liability_coverage(text)
    keywords = %w[일상배상 배상책임 대인배상 대물배상 신체배상 재물배상]
    keywords.any? { |kw| text.include?(kw) }
  end

  def calculate_confidence(insurer, valid_until, insured)
    score = 0
    score += 40 if insurer.present?
    score += 40 if valid_until.present?
    score += 20 if insured.present?
    score
  end

  def fallback_result(message)
    { success: false, error: message, insurer_name: nil, valid_until: nil, insured_name: nil, has_liability_coverage: nil, ocr_confidence: 0 }
  end
end
