module NotificationsHelper
  # 알림의 notifiable에 따라 적절한 경로 반환
  def notification_path(notifiable)
    return "#" unless notifiable

    case notifiable
    when Request
      if current_user.customer?
        customers_request_path(notifiable)
      elsif current_user.master?
        masters_request_path(notifiable)
      else
        admin_request_path(notifiable)
      end
    when InsuranceClaim
      if current_user.customer?
        customers_insurance_claim_path(notifiable)
      elsif current_user.master?
        masters_insurance_claim_path(notifiable)
      else
        admin_insurance_claim_path(notifiable)
      end
    when Estimate
      if current_user.customer?
        customers_estimate_path(notifiable)
      elsif current_user.master?
        masters_request_path(notifiable.request)
      else
        admin_request_path(notifiable.request)
      end
    when EscrowTransaction
      if current_user.master?
        masters_request_path(notifiable.request)
      else
        admin_escrow_transaction_path(notifiable)
      end
    else
      "#"
    end
  rescue ActiveRecord::RecordNotFound, NoMethodError
    "#"
  end
end
