class NotifyAllMastersJob < ApplicationJob
  queue_as :default

  def perform(request_id)
    request = Request.find_by(id: request_id)
    return unless request

    # MatchingService를 통해 Premium 제외한 모든 마스터에게 알림
    service = MatchingService.new(request)
    notified_count = service.notify_all_masters_except_premium

    Rails.logger.info "Notified #{notified_count} non-premium masters for request #{request_id}"
  rescue => e
    Rails.logger.error "Failed to notify all masters for request #{request_id}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
  end
end
