class BillingRenewalJob < ApplicationJob
  queue_as :default

  def perform
    # next_billing_at이 오늘 이하이고, billing_key가 있는 zone 구독자 전체
    due_subscriptions = Subscription.where(tier: :zone, billing_status: "active")
                                    .where.not(billing_key: nil)
                                    .where("next_billing_at <= ?", Time.current)

    due_subscriptions.find_each do |subscription|
      renew_subscription(subscription)
    end
  end

  private

  def renew_subscription(subscription)
    master = subscription.master
    return unless master

    order_id = "ZONE-RENEW-#{master.id}-#{Date.current.strftime('%Y%m')}-#{SecureRandom.hex(4).upcase}"

    toss = TossPaymentsService.new
    toss.charge_billing_key(
      billing_key: subscription.billing_key,
      customer_key: subscription.customer_key,
      amount: 99_000,
      order_id: order_id,
      order_name: "누수체크 전문가 등록 마스터 플랜 (월 99,000원)",
      customer_email: master.email,
      customer_name: master.name
    )

    subscription.update!(
      starts_on: Date.current,
      expires_on: Date.current + 1.month,
      next_billing_at: Date.current + 1.month,
      active: true
    )

    PaymentAuditLog.log_payment(
      user: master,
      action: "success",
      details: {
        plan: "zone",
        type: "renewal",
        amount: 99_000,
        order_id: order_id
      },
      ip_address: "system"
    )

    Rails.logger.info "[BillingRenewal] 갱신 성공: master_id=#{master.id} order_id=#{order_id}"

  rescue TossPaymentsService::PaymentError => e
    Rails.logger.error "[BillingRenewal] 결제 실패: master_id=#{master.id} error=#{e.message}"

    subscription.update!(billing_status: "failed")

    PaymentAuditLog.log_payment(
      user: master,
      action: "fail",
      details: {
        plan: "zone",
        type: "renewal",
        amount: 99_000,
        order_id: order_id,
        error: e.message
      },
      ip_address: "system"
    )

    # TODO: 결제 실패 알림 이메일 발송
  rescue => e
    Rails.logger.error "[BillingRenewal] 알 수 없는 오류: master_id=#{master.id} error=#{e.class} #{e.message}"
  end
end
