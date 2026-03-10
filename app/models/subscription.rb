class Subscription < ApplicationRecord
  belongs_to :master, class_name: "Master"

  enum tier: {
    free: 0,       # 무료: 월 5건 제한, 일반 매칭
    basic: 1,      # 베이직: 월 20,000원, 월 무제한, 일반 매칭
    premium: 2     # 프리미엄: 월 50,000원, 월 무제한, 우선 매칭, 프로필 상단 노출
  }

  validates :tier, presence: true
  validates :monthly_fee, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true).where("expires_on > ?", Date.current) }
  scope :premium, -> { where(tier: :premium) }
  scope :basic_or_premium, -> { where(tier: [:basic, :premium]) }

  # 티어별 특징 반환
  def features_for_tier
    case tier
    when "free"
      {
        monthly_limit: 5,
        priority_matching: false,
        profile_boost: false,
        ad_free: false,
        display_name: "무료 플랜",
        description: "누수체크를 시작해보세요"
      }
    when "basic"
      {
        monthly_limit: nil,  # 무제한
        priority_matching: false,
        profile_boost: false,
        ad_free: true,
        display_name: "베이직 플랜",
        description: "무제한으로 고객을 만나보세요"
      }
    when "premium"
      {
        monthly_limit: nil,  # 무제한
        priority_matching: true,   # 신규 체크 우선 알림 (5분 선행)
        profile_boost: true,        # 프로필 상단 노출
        ad_free: true,
        display_name: "프리미엄 플랜",
        description: "우선 매칭으로 더 많은 기회를"
      }
    end
  end

  # 구독 갱신
  def renew!(months: 1)
    update!(
      starts_on: Date.current,
      expires_on: Date.current + months.months
    )
  end

  # 구독 활성화 여부
  def active?
    super && expires_on > Date.current
  end

  # 이번 달 클레임 가능 건수 확인
  def can_claim_request?
    return true if basic? || premium?
    return true if free? && monthly_claimed_count < 5
    false
  end

  # 이번 달 클레임한 건수
  def monthly_claimed_count
    return 0 unless master
    master.assigned_requests.where("created_at >= ?", 1.month.ago).count
  end

  # 남은 클레임 가능 건수
  def remaining_claims
    return Float::INFINITY if basic? || premium?
    [5 - monthly_claimed_count, 0].max
  end

  # 월 구독료 설정
  def set_monthly_fee_by_tier!
    self.monthly_fee = case tier
    when "free" then 0
    when "basic" then 20_000
    when "premium" then 50_000
    else 0
    end
  end
end
