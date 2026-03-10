class Master < User
  has_one :master_profile, foreign_key: :user_id, dependent: :destroy, inverse_of: :user
  has_one :subscription, foreign_key: :master_id, dependent: :destroy
  has_many :assigned_requests, class_name: "Request", foreign_key: :master_id, dependent: :nullify, inverse_of: :master
  has_many :estimates, foreign_key: :master_id, dependent: :destroy, inverse_of: :master
  has_many :reviews, foreign_key: :master_id, dependent: :destroy, inverse_of: :master
  has_many :escrow_transactions, foreign_key: :master_id, dependent: :restrict_with_error, inverse_of: :master
  has_many :prepared_insurance_claims, class_name: "InsuranceClaim", foreign_key: :prepared_by_master_id, dependent: :nullify

  accepts_nested_attributes_for :master_profile

  after_create :create_default_profile
  after_create :create_default_subscription

  delegate :verified?, :license_number, :experience_years, to: :master_profile, allow_nil: true

  def average_rating
    reviews.average(:overall_rating)&.round(2) || 0.0
  end

  def total_reviews_count
    reviews.count
  end

  def active_requests
    assigned_requests.where.not(status: [:closed, :cancelled])
  end

  # 구독 관련 헬퍼 메서드
  def premium?
    subscription&.premium? && subscription.active?
  end

  def basic?
    subscription&.basic? && subscription.active?
  end

  def free?
    !subscription || subscription.free?
  end

  def can_claim_request?
    subscription&.can_claim_request? || false
  end

  def remaining_claims
    subscription&.remaining_claims || 0
  end

  def subscription_display_name
    subscription&.features_for_tier&.dig(:display_name) || "무료 플랜"
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id name email phone address created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[master_profile assigned_requests]
  end

  private

  def create_default_profile
    # 신규 가입 시 verified: false로 시작 (관리자 승인 필요)
    create_master_profile!(verified: false) unless master_profile.present?
  end

  def create_default_subscription
    # 신규 가입 시 무료 플랜으로 시작
    create_subscription!(
      tier: :free,
      monthly_fee: 0,
      starts_on: Date.current,
      expires_on: 99.years.from_now,  # 무료 플랜은 만료 없음
      active: true
    ) unless subscription.present?
  end
end
