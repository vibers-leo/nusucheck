class PgWebhooksController < ApplicationController
  # 웹훅은 CSRF 토큰 없이 호출됨
  skip_before_action :verify_authenticity_token
  # Devise 인증 우회
  skip_before_action :authenticate_user!, raise: false

  # 웹훅 서명 검증 (보안)
  before_action :verify_toss_signature, only: :toss

  # POST /pg/webhooks/toss
  def toss
    payload = JSON.parse(request.body.read)
    Rails.logger.info "[Toss Webhook] 수신: #{payload['eventType']}"

    event_type = payload["eventType"]
    data       = payload["data"]

    # 감사 로그: 웹훅 수신
    PaymentAuditLog.log_payment(
      action: "webhook_received",
      details: {
        event_type: event_type,
        order_id: data&.dig("orderId"),
        status: data&.dig("status"),
        payload: payload
      },
      ip_address: request.remote_ip
    )

    case event_type
    when "PAYMENT_STATUS_CHANGED"
      handle_payment_status_changed(data)
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "[Toss Webhook] JSON 파싱 오류: #{e.message}"
    # 감사 로그: 파싱 오류
    PaymentAuditLog.log_payment(
      action: "fail",
      details: { error_type: "JSON::ParserError", error_message: e.message },
      ip_address: request.remote_ip
    )
    head :bad_request
  rescue => e
    Rails.logger.error "[Toss Webhook] 처리 오류: #{e.message}"
    # 감사 로그: 처리 오류
    PaymentAuditLog.log_payment(
      action: "fail",
      details: {
        error_type: e.class.to_s,
        error_message: e.message,
        event_type: event_type
      },
      ip_address: request.remote_ip
    )
    head :ok  # 토스는 200이 아니면 재시도하므로 항상 200 응답
  end

  private

  # 웹훅 서명 검증 (HMAC SHA256)
  # 토스페이먼츠에서 보낸 웹훅인지 검증하여 위조 방지
  def verify_toss_signature
    webhook_secret = ENV["TOSS_WEBHOOK_SECRET"]
    unless webhook_secret.present?
      if Rails.env.production?
        Rails.logger.error "[Toss Webhook] TOSS_WEBHOOK_SECRET 미설정 - 프로덕션에서 웹훅 거부"
        render json: { error: "Webhook not configured" }, status: :service_unavailable
        return
      else
        Rails.logger.warn "[Toss Webhook] TOSS_WEBHOOK_SECRET 미설정 - 개발 환경 스킵"
        return
      end
    end

    # 헤더에서 서명 읽기
    signature = request.headers["X-TossPayments-Signature"]
    unless signature.present?
      Rails.logger.error "[Toss Webhook] 서명 헤더 없음"
      PaymentAuditLog.log_payment(
        action: "fail",
        details: { error_type: "MissingSignature", error_message: "X-TossPayments-Signature header missing" },
        ip_address: request.remote_ip
      )
      render json: { error: "Missing signature" }, status: :unauthorized
      return
    end

    # request body 읽기
    body = request.body.read
    request.body.rewind  # 다시 읽을 수 있도록 rewind

    # HMAC SHA256으로 서명 계산
    expected_signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", webhook_secret, body)
    )

    # 서명 비교
    unless ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)
      Rails.logger.error "[Toss Webhook] 서명 불일치 - 위조된 웹훅 가능성"
      PaymentAuditLog.log_payment(
        action: "fail",
        details: {
          error_type: "InvalidSignature",
          error_message: "Signature verification failed",
          received_signature: signature[0..20] + "...",  # 일부만 로깅 (보안)
          ip_address: request.remote_ip
        },
        ip_address: request.remote_ip
      )
      render json: { error: "Invalid signature" }, status: :unauthorized
      return
    end

    Rails.logger.info "[Toss Webhook] 서명 검증 성공"
  end

  def handle_payment_status_changed(data)
    return unless data

    order_id    = data["orderId"]
    status      = data["status"]
    payment_key = data["paymentKey"]

    return unless order_id.present?

    escrow = EscrowTransaction.find_by(toss_order_id: order_id)
    return unless escrow

    case status
    when "DONE"
      # 성공 콜백(success action)에서 이미 처리했으므로 중복 처리 방지
      Rails.logger.info "[Toss Webhook] DONE (이미 처리됨): #{order_id}"
    when "CANCELED", "PARTIAL_CANCELED"
      # 결제 취소 → 에스크로 환불 처리
      ActiveRecord::Base.transaction do
        escrow.refund! if escrow.may_refund?
      end
      # 감사 로그: 환불 처리
      PaymentAuditLog.log_payment(
        escrow_transaction: escrow,
        action: "refund",
        details: {
          order_id: order_id,
          status: status,
          payment_key: payment_key,
          canceled_via: "webhook"
        },
        ip_address: "TOSS_WEBHOOK"
      )
      Rails.logger.info "[Toss Webhook] 취소 처리 완료: #{order_id}"
    when "ABORTED"
      Rails.logger.warn "[Toss Webhook] 결제 중단: #{order_id}"
    end
  end
end
