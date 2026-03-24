# frozen_string_literal: true

class Payments::WebhooksController < ApplicationController
  # 웹훅은 CSRF 토큰 없이 호출됨
  skip_before_action :verify_authenticity_token
  # Devise 인증 우회
  skip_before_action :authenticate_user!, raise: false

  before_action :verify_webhook_signature!

  # POST /payments/webhook
  # 포트원에서 호출하는 웹훅
  def portone
    imp_uid = params[:imp_uid]
    merchant_uid = params[:merchant_uid]
    status = params[:status]

    Rails.logger.info "[PortOne Webhook] 수신: imp_uid=#{imp_uid}, status=#{status}"

    # 감사 로그: 웹훅 수신
    PaymentAuditLog.log_payment(
      action: "webhook_received",
      details: {
        imp_uid: imp_uid,
        merchant_uid: merchant_uid,
        status: status,
        payload: params.to_unsafe_h
      },
      ip_address: request.remote_ip
    )

    unless imp_uid.present?
      Rails.logger.error "[PortOne Webhook] imp_uid 없음"
      head :bad_request
      return
    end

    # 포트원 API로 결제 정보 재조회 (위조 방지)
    port_one = PortOneService.new
    payment = port_one.get_payment(imp_uid)

    # 에스크로 거래 찾기
    escrow = EscrowTransaction.find_by(toss_order_id: merchant_uid)

    case payment["status"]
    when "paid"
      # 결제 성공 (callback에서 이미 처리했으므로 중복 방지)
      Rails.logger.info "[PortOne Webhook] 결제 성공 (이미 처리됨): #{imp_uid}"

    when "cancelled"
      # 결제 취소 → 에스크로 환불 처리
      if escrow
        ActiveRecord::Base.transaction do
          escrow.refund! if escrow.may_refund?
        end

        # 감사 로그: 환불 처리
        PaymentAuditLog.log_payment(
          escrow_transaction: escrow,
          action: "refund",
          details: {
            imp_uid: imp_uid,
            merchant_uid: merchant_uid,
            cancel_amount: payment["cancel_amount"],
            cancel_reason: payment["cancel_reason"],
            canceled_via: "webhook"
          },
          ip_address: "PORTONE_WEBHOOK"
        )
        Rails.logger.info "[PortOne Webhook] 환불 처리 완료: #{imp_uid}"
      else
        Rails.logger.warn "[PortOne Webhook] 에스크로 거래 없음: merchant_uid=#{merchant_uid}"
      end

    when "failed"
      Rails.logger.warn "[PortOne Webhook] 결제 실패: #{imp_uid}, reason=#{payment['fail_reason']}"

      # 감사 로그: 결제 실패
      PaymentAuditLog.log_payment(
        action: "fail",
        details: {
          imp_uid: imp_uid,
          merchant_uid: merchant_uid,
          fail_reason: payment["fail_reason"],
          canceled_via: "webhook"
        },
        ip_address: "PORTONE_WEBHOOK"
      )

    else
      Rails.logger.info "[PortOne Webhook] 기타 상태: #{payment['status']}"
    end

    head :ok

  rescue PortOneService::PaymentError => e
    Rails.logger.error "[PortOne Webhook] 결제 조회 오류: #{e.message}"
    # 감사 로그: 조회 오류
    PaymentAuditLog.log_payment(
      action: "fail",
      details: {
        error_type: "PortOneService::PaymentError",
        error_message: e.message,
        imp_uid: imp_uid
      },
      ip_address: request.remote_ip
    )
    head :ok  # 포트원은 200이 아니면 재시도하므로 항상 200 응답

  rescue => e
    Rails.logger.error "[PortOne Webhook] 처리 오류: #{e.message}"
    # 감사 로그: 처리 오류
    PaymentAuditLog.log_payment(
      action: "fail",
      details: {
        error_type: e.class.to_s,
        error_message: e.message,
        imp_uid: imp_uid
      },
      ip_address: request.remote_ip
    )
    head :ok  # 포트원은 200이 아니면 재시도하므로 항상 200 응답
  end

  private

  def verify_webhook_signature!
    signature = request.headers['x-portone-signature']
    return if Rails.env.development? && signature.blank?

    unless signature.present?
      render json: { error: 'Missing signature' }, status: :unauthorized
      return false
    end

    secret = ENV['PORTONE_WEBHOOK_SECRET']
    return true if secret.blank? && Rails.env.development?

    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, request.raw_post)
    unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      Rails.logger.warn("[PortOne] 웹훅 서명 불일치")
      render json: { error: 'Invalid signature' }, status: :unauthorized
      return false
    end
    true
  end
end
