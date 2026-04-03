# frozen_string_literal: true

class InsuranceSubmissionService
  attr_reader :insurance_claim, :errors

  def initialize(insurance_claim)
    @insurance_claim = insurance_claim
    @errors = []
  end

  # 보험사에 자동 제출 (이메일 발송)
  def submit_to_insurance_company!
    return false unless valid_for_submission?

    begin
      # 1. PDF 생성
      pdf_data = generate_pdf

      # 2. 보험사 정보 가져오기
      company_info = get_company_info

      # 3. 이메일 발송 (백그라운드 잡)
      InsuranceSubmissionMailer.submit_to_company(
        insurance_claim: @insurance_claim,
        company_info: company_info,
        pdf_data: pdf_data
      ).deliver_later

      # 4. 제출 로그 기록
      log_submission

      # 5. 상태 업데이트 (submitted → under_review)
      @insurance_claim.start_review! if @insurance_claim.may_start_review?

      # 6. 고객에게 알림
      notify_customer_submission_success

      true
    rescue StandardError => e
      @errors << e.message
      Rails.logger.error "[InsuranceSubmissionService] 제출 실패: #{e.message}"
      false
    end
  end

  # 수동 제출 가이드 제공 (보험사 정보 반환)
  def manual_submission_guide
    company_info = get_company_info
    return nil unless company_info

    {
      company_name: company_info[:name],
      phone: company_info[:phone],
      app_name: company_info[:app_name],
      website: company_info[:website],
      claim_menu: company_info[:claim_menu],
      badge_color: company_info[:badge_color],
      pdf_download_url: pdf_download_url,
      required_documents: required_documents_list
    }
  end

  # 모든 보험사 가이드 목록
  def self.all_companies_guide
    INSURANCE_COMPANIES.map do |company_name, info|
      {
        company_name: info[:name],
        phone: info[:phone],
        app_name: info[:app_name],
        website: info[:website],
        claim_menu: info[:claim_menu],
        badge_color: info[:badge_color]
      }
    end
  end

  private

  def valid_for_submission?
    # 필수 정보 확인
    if @insurance_claim.insurance_company.blank?
      @errors << "보험사를 선택해주세요"
      return false
    end

    unless @insurance_claim.submitted? || @insurance_claim.draft?
      @errors << "현재 상태에서는 제출할 수 없습니다"
      return false
    end

    # 보험사 정보 존재 확인
    if get_company_info.nil?
      @errors << "등록되지 않은 보험사입니다"
      return false
    end

    true
  end

  def generate_pdf
    InsuranceClaimPdfService.new(@insurance_claim).generate.render
  end

  def get_company_info
    INSURANCE_COMPANIES[@insurance_claim.insurance_company]
  end

  def pdf_download_url
    Rails.application.routes.url_helpers.download_pdf_customers_insurance_claim_url(
      @insurance_claim,
      host: ENV.fetch("APP_DOMAIN", "nusucheck.fly.dev"),
      protocol: "https"
    )
  end

  def required_documents_list
    [
      "보험 청구 신청서 (PDF)",
      "누수 피해 사진",
      "견적서 (있는 경우)",
      "신분증 사본"
    ]
  end

  def log_submission
    Rails.logger.info "[InsuranceSubmission] 보험사 제출 완료: " \
                      "claim_id=#{@insurance_claim.id}, " \
                      "company=#{@insurance_claim.insurance_company}"
  end

  def notify_customer_submission_success
    # 고객에게 실시간 알림
    NotificationService.notify(
      recipient: @insurance_claim.customer,
      action: "insurance_submitted",
      message: "#{@insurance_claim.insurance_company}에 보험 청구서가 제출되었습니다.",
      notifiable: @insurance_claim
    )

    # 이메일 알림 (선택적)
    # InsuranceClaimMailerJob.perform_later("submitted_to_company", @insurance_claim.id)
  end
end
