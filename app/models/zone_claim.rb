class ZoneClaim < ApplicationRecord
  belongs_to :master, class_name: "User"
  belongs_to :service_zone

  validates :master_id, uniqueness: { scope: :service_zone_id, message: "이미 선점한 구역이에요" }
  validate :zone_not_full, on: :create

  scope :active, -> { where(status: "active") }
  scope :expired, -> { where(status: "expired") }

  before_create :set_claimed_at
  after_save :update_slot_count
  after_destroy :update_slot_count

  def active?
    status == "active"
  end

  def release!
    update!(status: "released", released_at: Time.current)
  end

  def expire!
    update!(status: "expired")
  end

  # 요청 완료/취소 시 active_assignments 감소
  def decrement_active!
    update_column(:active_assignments, [active_assignments - 1, 0].max) if active_assignments > 0
  end

  # 로테이션 순서 (last_assigned_at이 가장 오래된 것이 1순위)
  def rotation_priority
    last_assigned_at || Time.at(0)
  end

  private

  def zone_not_full
    return unless service_zone
    if service_zone.full? && status == "active"
      errors.add(:base, "이 구역은 모든 슬롯이 선점됐어요")
    end
  end

  def set_claimed_at
    self.claimed_at ||= Time.current
    self.expires_at ||= 1.year.from_now
  end

  def update_slot_count
    service_zone.update_column(:claimed_slots_count, service_zone.zone_claims.active.count)
  end
end
