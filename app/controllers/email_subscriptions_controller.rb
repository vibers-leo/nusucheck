class EmailSubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    @subscription = EmailSubscription.new(email: params[:email])

    if @subscription.save
      # juuuno@naver.com으로 알림 발송 (SMTP 설정이 있을 때만)
      if ENV["SMTP_PASSWORD"].present?
        begin
          SubscriptionMailer.new_subscriber(@subscription).deliver_now
        rescue => e
          Rails.logger.error "이메일 발송 실패: #{e.message}"
          # 에러가 발생해도 사용자에게는 성공 메시지 표시 (DB 저장은 성공했으므로)
        end
      else
        Rails.logger.warn "SMTP_PASSWORD가 설정되지 않아 이메일 발송을 건너뜁니다."
      end

      redirect_to root_path, notice: "출시 알림 신청이 완료되었습니다! 🎉"
    else
      redirect_to root_path, alert: "이메일 주소를 확인해주세요. #{@subscription.errors.full_messages.join(', ')}"
    end
  end
end
