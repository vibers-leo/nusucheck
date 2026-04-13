class Masters::BillingController < ApplicationController
  include MasterAccessible

  before_action :set_subscription

  ZONE_PLAN_AMOUNT = 99_000
  ZONE_PLAN_NAME   = "누수체크 전문가 등록 마스터 플랜 (월 99,000원)"

  # GET /masters/billing/new
  # 카드 등록 + 첫 결제 페이지 (토스 결제창)
  def new
    if @subscription.zone? && @subscription.active?
      redirect_to masters_billing_path, notice: "이미 전문가 등록 마스터 플랜을 이용 중이에요."
      return
    end

    @customer_key   = "MASTER-#{current_user.id}-#{SecureRandom.hex(4)}"
    @success_url    = masters_billing_success_url
    @fail_url       = masters_billing_fail_url
    @toss_client_key = ENV["TOSS_CLIENT_KEY"]

    unless @toss_client_key.present?
      redirect_to masters_subscriptions_path, alert: "결제 서비스가 준비 중입니다."
      return
    end

    session[:billing_customer_key] = @customer_key
  end

  # GET /masters/billing
  # 현재 구독/결제 현황
  def show
  end

  # GET /masters/billing/success
  # 빌링키 발급 성공 → 즉시 첫 결제
  def success
    auth_key     = params[:authKey]
    customer_key = params[:customerKey] || session.delete(:billing_customer_key)

    unless auth_key.present? && customer_key.present?
      redirect_to new_masters_billing_path, alert: "빌링키 발급 정보가 올바르지 않습니다."
      return
    end

    toss = TossPaymentsService.new
    billing_key = nil

    # 빌링키 발급
    billing_result = toss.issue_billing_key(auth_key: auth_key, customer_key: customer_key)
    billing_key = billing_result["billingKey"]

    # 첫 결제 실행
    order_id = "ZONE-#{current_user.id}-#{Date.current.strftime('%Y%m')}-#{SecureRandom.hex(4).upcase}"
    toss.charge_billing_key(
      billing_key: billing_key,
      customer_key: customer_key,
      amount: ZONE_PLAN_AMOUNT,
      order_id: order_id,
      order_name: ZONE_PLAN_NAME,
      customer_email: current_user.email,
      customer_name: current_user.name
    )

    # 구독 활성화 (결제 성공 후에만)
    @subscription.activate_with_billing!(
      billing_key: billing_key,
      customer_key: customer_key
    )

    PaymentAuditLog.log_payment(
      user: current_user,
      action: "success",
      details: {
        plan: "zone",
        amount: ZONE_PLAN_AMOUNT,
        order_id: order_id,
        billing_key: billing_key
      },
      ip_address: request.remote_ip
    )

    redirect_to masters_billing_path, notice: "🎉 전문가 등록 마스터 플랜이 시작되었어요! 내 구역에서 우선 노출됩니다."

  rescue TossPaymentsService::PaymentError => e
    Rails.logger.error "[Billing] 빌링키/결제 실패: #{e.message}"

    # 빌링키가 발급됐지만 결제 실패 → 빌링키 비활성화 (고아 빌링키 방지)
    if billing_key.present?
      begin
        toss.delete_billing_key(billing_key)
        Rails.logger.info "[Billing] 고아 빌링키 삭제: #{billing_key}"
      rescue => cleanup_error
        Rails.logger.error "[Billing] 빌링키 삭제 실패 (수동 정리 필요): #{billing_key} / #{cleanup_error.message}"
      end
    end

    PaymentAuditLog.log_payment(
      user: current_user,
      action: "fail",
      details: { error: e.message, billing_key: billing_key },
      ip_address: request.remote_ip
    )

    redirect_to new_masters_billing_path, alert: "결제 처리 중 오류가 발생했어요. 다시 시도해주세요."
  rescue => e
    Rails.logger.error "[Billing] 알 수 없는 오류: #{e.class} - #{e.message}"
    redirect_to new_masters_billing_path, alert: "일시적인 오류가 발생했어요. 잠시 후 다시 시도해주세요."
  end

  # GET /masters/billing/fail
  def fail
    error_message = params[:message] || "결제가 취소되었어요."
    redirect_to new_masters_billing_path, alert: error_message
  end

  # DELETE /masters/billing
  # 자동결제 해지
  def destroy
    unless @subscription.has_billing_key?
      redirect_to masters_billing_path, alert: "자동결제 정보가 없어요."
      return
    end

    @subscription.update!(
      billing_status: "cancelled",
      billing_key: nil,
      tier: :free,
      monthly_fee: 0,
      expires_on: @subscription.expires_on  # 현재 만료일까지는 유지
    )

    redirect_to masters_billing_path, notice: "자동결제가 해지되었어요. 현재 구독은 만료일까지 유지됩니다."
  end

  private

  def set_subscription
    @subscription = current_user.subscription || current_user.create_subscription!(
      tier: :free,
      monthly_fee: 0,
      starts_on: Date.current,
      expires_on: 99.years.from_now
    )
  end
end
