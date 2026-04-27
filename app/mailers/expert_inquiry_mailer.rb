class ExpertInquiryMailer < ApplicationMailer
  ADMIN_EMAILS = [
    ENV.fetch("SMTP_USERNAME", "juuuno1116@gmail.com"),
    "cleanmentor2@gmail.com"
  ].uniq.freeze

  # 문의 접수 시 관리자에게
  def inquiry_received(inquiry)
    @inquiry = inquiry
    mail(to: ADMIN_EMAILS, subject: "[누수체크] 전문가 등록 문의 - #{inquiry.name}")
  end

  # fallback (DB 저장 실패 시 raw params로)
  def inquiry_received_raw(name:, phone:, email:, message:)
    @inquiry = OpenStruct.new(name: name, phone: phone, email: email,
                               message: message, created_at: Time.current, id: nil)
    mail(to: ADMIN_EMAILS, subject: "[누수체크] 전문가 등록 문의 - #{name}")
  end

  # 승인 알림 → 전문가에게
  def approval_notification(inquiry, registration_url)
    @inquiry          = inquiry
    @registration_url = registration_url
    mail(to: inquiry.email, subject: "[누수체크] 전문가 파트너 승인 안내 🎉")
  end

  # 거절 알림 → 전문가에게
  def rejection_notification(inquiry)
    @inquiry = inquiry
    mail(to: inquiry.email, subject: "[누수체크] 전문가 파트너 신청 결과 안내")
  end
end
