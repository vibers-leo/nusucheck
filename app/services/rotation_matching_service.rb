class RotationMatchingService
  MAX_CONCURRENT_REQUESTS = 5

  attr_reader :request

  def initialize(request)
    @request = request
  end

  # 로테이션 배정 실행
  def assign!
    zone = find_zone_for_address(request.address)

    unless zone
      Rails.logger.info "[RotationMatching] 구역 매칭 실패: #{request.address} → 공개 오더로 전환"
      return fallback_to_open_order!
    end

    master = find_next_master(zone)

    unless master
      Rails.logger.info "[RotationMatching] #{zone.display_name} 가용 전문가 없음 → 공개 오더로 전환"
      return fallback_to_open_order!
    end

    # 배정
    request.assign!(master: master)

    # 로테이션 카운터 업데이트
    claim = zone.zone_claims.active.find_by(master_id: master.id)
    if claim
      claim.update!(
        last_assigned_at: Time.current,
        total_assignments: claim.total_assignments + 1,
        active_assignments: claim.active_assignments + 1
      )
    end

    Rails.logger.info "[RotationMatching] ✅ 배정 완료: #{zone.display_name} → #{master.name} (총 #{claim&.total_assignments}건)"

    # 전문가에게 알림
    begin
      NotificationService.notify(
        recipient: master,
        actor: request.customer,
        notifiable: request,
        action: "request_assigned",
        message: "#{request.address}에서 새 요청이 배정됐어요. 확인해 주세요!"
      )
    rescue => e
      Rails.logger.warn "[RotationMatching] 알림 발송 실패 (배정은 완료): #{e.message}"
    end

    master
  end

  # 구역별 로테이션 현황 조회
  def self.rotation_status(zone)
    zone.zone_claims.active
        .includes(:master)
        .order(last_assigned_at: :asc)
        .map do |claim|
      {
        master_id: claim.master_id,
        master_name: claim.master&.name,
        last_assigned_at: claim.last_assigned_at,
        total_assignments: claim.total_assignments,
        active_assignments: claim.active_assignments,
        next_in_line: claim == zone.zone_claims.active.order(last_assigned_at: :asc).first
      }
    end
  end

  private

  # 주소에서 구역 찾기
  def find_zone_for_address(address)
    return nil if address.blank?

    ServiceZone.active.find_each do |zone|
      next unless zone.districts.is_a?(Array)
      zone.districts.each do |district|
        return zone if address.include?(district)
      end
    end
    nil
  end

  # 라운드 로빈으로 다음 전문가 찾기
  def find_next_master(zone)
    candidates = zone.zone_claims
                     .active
                     .where(master_id: active_subscription_master_ids)
                     .order(Arel.sql("last_assigned_at ASC NULLS FIRST"))

    candidates.each do |claim|
      master = claim.master
      next unless master
      next unless master.respond_to?(:verified?) && master.verified?
      next if master_too_busy?(master)

      return master
    end

    nil
  end

  # 활성 구독 전문가 ID 목록
  def active_subscription_master_ids
    Subscription.where(active: true)
                .where("expires_on > ?", Date.current)
                .pluck(:master_id)
  end

  # 동시 진행 건수 체크
  def master_too_busy?(master)
    master.assigned_requests
          .where.not(status: [:closed, :cancelled])
          .count >= MAX_CONCURRENT_REQUESTS
  end

  # 공개 오더 풀로 전환
  def fallback_to_open_order!
    if request.may_publish?
      request.publish!
      MatchingService.new(request).notify_masters
      Rails.logger.info "[RotationMatching] 공개 오더로 전환: Request ##{request.id}"
    end
    nil
  end
end
