class NotificationService
  def self.notify(recipient:, action:, message:, actor: nil, notifiable: nil)
    notification = Notification.create!(
      recipient: recipient,
      actor: actor,
      notifiable: notifiable,
      action: action,
      message: message
    )

    # ActionCable로 실시간 알림 브로드캐스트
    NotificationsChannel.broadcast_to(
      recipient,
      notification: render_notification(notification),
      icon: notification.icon,
      title: action_title(action),
      message: message
    )

    notification
  end

  # 전문가 신청 알림 (고객에게)
  def self.notify_master_applied(request, master)
    notify(
      recipient: request.customer,
      action: "master_applied",
      message: "#{master.name} 전문가가 체크 신청을 보냈어요",
      actor: master,
      notifiable: request
    )
  end

  # 신고 배정 알림 (+ 이메일)
  def self.notify_request_assigned(request)
    return unless request.master

    notify(
      recipient: request.master,
      action: "request_assigned",
      message: "새로운 누수 신고가 배정되었어요",
      actor: request.customer,
      notifiable: request
    )

    # 고객에게 이메일 알림
    RequestMailer.master_assigned(request).deliver_later
  rescue => e
    Rails.logger.error("[NotificationService] 이메일 발송 실패 (master_assigned): #{e.message}")
  end

  # 견적 제출 알림 (+ 이메일)
  def self.notify_estimate_submitted(estimate)
    notify(
      recipient: estimate.request.customer,
      action: "estimate_submitted",
      message: "#{estimate.master.name}님이 견적을 제출했어요",
      actor: estimate.master,
      notifiable: estimate
    )

    # 고객에게 이메일 알림
    RequestMailer.estimate_submitted(estimate.request).deliver_later
  rescue => e
    Rails.logger.error("[NotificationService] 이메일 발송 실패 (estimate_submitted): #{e.message}")
  end

  # 견적 수락 알림
  def self.notify_estimate_accepted(estimate)
    notify(
      recipient: estimate.master,
      action: "estimate_accepted",
      message: "#{estimate.request.customer.name}님이 견적을 수락했어요",
      actor: estimate.request.customer,
      notifiable: estimate
    )
  end

  # 공사 완료 알림 (+ 이메일)
  def self.notify_construction_completed(request)
    notify(
      recipient: request.customer,
      action: "construction_completed",
      message: "공사가 완료되었어요. 확인 후 완료 처리를 해주세요",
      actor: request.master,
      notifiable: request
    )

    # 고객에게 이메일 알림
    RequestMailer.construction_completed(request).deliver_later
  rescue => e
    Rails.logger.error("[NotificationService] 이메일 발송 실패 (construction_completed): #{e.message}")
  end

  # 보험청구 검토 요청 알림
  def self.notify_insurance_review_requested(insurance_claim)
    notify(
      recipient: insurance_claim.customer,
      action: "insurance_review_requested",
      message: "#{insurance_claim.prepared_by_master.name}님이 보험청구서를 작성했어요",
      actor: insurance_claim.prepared_by_master,
      notifiable: insurance_claim
    )
  end

  # 보험청구 승인 알림
  def self.notify_insurance_approved(insurance_claim)
    return unless insurance_claim.prepared_by_master

    notify(
      recipient: insurance_claim.prepared_by_master,
      action: "insurance_approved",
      message: "#{insurance_claim.customer.name}님이 보험청구서를 승인했어요",
      actor: insurance_claim.customer,
      notifiable: insurance_claim
    )
  end

  # 보험청구 수정 요청 알림
  def self.notify_insurance_change_requested(insurance_claim)
    return unless insurance_claim.prepared_by_master

    notify(
      recipient: insurance_claim.prepared_by_master,
      action: "insurance_change_requested",
      message: "#{insurance_claim.customer.name}님이 수정을 요청했어요",
      actor: insurance_claim.customer,
      notifiable: insurance_claim
    )
  end

  # 에스크로 지급 알림
  def self.notify_payment_released(escrow_transaction)
    notify(
      recipient: escrow_transaction.master,
      action: "payment_released",
      message: "대금 #{ActionController::Base.helpers.number_to_currency(escrow_transaction.master_payout, unit: '₩', precision: 0)}이 지급되었어요",
      actor: nil,
      notifiable: escrow_transaction
    )
  end

  private

  ACTION_TITLES = {
    "master_applied" => "전문가 신청",
    "request_assigned" => "체크 배정",
    "estimate_submitted" => "견적 도착",
    "estimate_accepted" => "견적 수락",
    "construction_completed" => "공사 완료",
    "insurance_review_requested" => "보험청구 검토",
    "insurance_approved" => "보험청구 승인",
    "insurance_change_requested" => "수정 요청",
    "payment_released" => "대금 지급"
  }.freeze

  def self.action_title(action)
    ACTION_TITLES[action] || "새 알림"
  end

  def self.render_notification(notification)
    ApplicationController.render(
      partial: 'notifications/notification',
      locals: { notification: notification },
      formats: [:html]
    )
  end
end
