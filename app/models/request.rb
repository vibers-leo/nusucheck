class Request < ApplicationRecord
  include AASM

  belongs_to :customer, class_name: "Customer", inverse_of: :requests
  belongs_to :master, class_name: "Master", optional: true, inverse_of: :assigned_requests
  has_many :master_applications, dependent: :destroy
  has_many :applicant_masters, through: :master_applications, source: :master
  has_many :estimates, dependent: :destroy
  has_many :escrow_transactions, dependent: :destroy
  has_one :review, dependent: :destroy
  has_many :insurance_claims, dependent: :nullify
  has_many :messages, class_name: "::Message", dependent: :destroy
  has_many_attached :photos
  has_many_attached :videos

  validates :symptom_type, presence: true
  validates :address, presence: true
  validates :customer, presence: true
  validate :videos_content_type_and_size

  enum :symptom_type, {
    wall_leak: 0,
    ceiling_leak: 1,
    floor_leak: 2,
    pipe_leak: 3,
    toilet_leak: 4,
    outdoor_leak: 5
  }

  enum :building_type, {
    apartment: 0,
    villa: 1,
    house: 2,
    office: 3,
    retail_store: 4,
    factory: 5,
    other_building: 6
  }

  enum :detection_result, {
    result_pending: 0,
    leak_confirmed: 1,
    no_leak: 2,
    inconclusive: 3
  }, prefix: :detection

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  scope :active, -> { where.not(status: [:closed, :cancelled]) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_master, ->(master) { where(master: master) }

  scope :open_orders, -> { where(status: :open) }

  # AASM State Machine - 14 states
  aasm column: :status, whiny_transitions: true do
    state :reported, initial: true
    state :open          # 공개 오더 풀 (전문가 선착순 선택 가능)
    state :assigned
    state :visiting
    state :detecting
    state :no_leak_found
    state :estimate_pending
    state :estimate_submitted
    state :construction_agreed
    state :escrow_deposited
    state :constructing
    state :construction_completed
    state :closed
    state :cancelled

    # 공개 오더 풀에 등록 (Admin이 실행)
    event :publish do
      transitions from: :reported, to: :open
    end

    # 전문가가 선착순으로 선택 (클레임)
    event :claim do
      before do |master:|
        self.master = master
        self.assigned_at = Time.current
      end
      transitions from: :open, to: :assigned, guard: :master_present?
    end

    # 관리자 직접 배정 (수동 오버라이드)
    event :assign do
      before do |master:|
        self.master = master
        self.assigned_at = Time.current
      end
      transitions from: [:reported, :open], to: :assigned, guard: :master_present?
    end

    # 방문 시작
    event :visit do
      before { self.visit_started_at = Time.current }
      transitions from: :assigned, to: :visiting
    end

    # 현장 도착 → 탐지 시작
    event :arrive do
      before { self.detection_started_at = Time.current }
      transitions from: :visiting, to: :detecting
    end

    # 탐지 완료 (누수 확인)
    event :detection_complete do
      transitions from: :detecting, to: :estimate_pending,
                  guard: :leak_confirmed?
    end

    # 탐지 실패 (누수 미확인)
    event :detection_fail do
      before { self.detection_result = :no_leak }
      transitions from: :detecting, to: :no_leak_found
    end

    # 견적 제출
    event :submit_estimate do
      transitions from: :estimate_pending, to: :estimate_submitted,
                  guard: :has_estimates?
    end

    # 견적 수락
    event :accept_estimate do
      transitions from: :estimate_submitted, to: :construction_agreed
    end

    # 에스크로 입금
    event :deposit_escrow do
      transitions from: :construction_agreed, to: :escrow_deposited,
                  guard: :escrow_deposited_check?
    end

    # 공사 시작
    event :start_construction do
      before { self.construction_started_at = Time.current }
      transitions from: :escrow_deposited, to: :constructing
    end

    # 공사 완료
    event :complete_construction do
      before { self.construction_completed_at = Time.current }
      transitions from: :constructing, to: :construction_completed
    end

    # 고객 완료 확인 → 대금 지급
    event :confirm_completion do
      transitions from: :construction_completed, to: :closed,
                  after: :release_escrow_payment
    end

    # 누수 미확인 종료 (비용 미청구)
    event :close_no_charge do
      before { self.closed_at = Time.current }
      transitions from: :no_leak_found, to: :closed
    end

    # 최종 종료 (관리자)
    event :finalize do
      before { self.closed_at = Time.current }
      transitions from: [:construction_completed], to: :closed
    end

    # 취소 (공사 진행 전 단계에서만 가능)
    event :cancel do
      before { self.closed_at = Time.current }
      transitions from: [:reported, :open, :assigned, :visiting, :detecting,
                         :no_leak_found, :estimate_pending, :estimate_submitted,
                         :construction_agreed],
                  to: :cancelled
    end
  end

  def accepted_estimate
    estimates.find_by(status: "accepted")
  end

  def under_warranty?
    warranty_expires_at.present? && warranty_expires_at > Time.current
  end

  def set_warranty!(months)
    return unless months.to_i > 0
    update!(
      warranty_period_months: months.to_i,
      warranty_expires_at: Time.current + months.to_i.months
    )
  end

  def has_complaint?
    customer_complaint.present?
  end

  def calculate_total_fee
    self.total_fee = trip_fee.to_d + detection_fee.to_d + construction_fee.to_d
  end

  def can_be_reviewed?
    closed? && review.nil?
  end

  def status_label
    I18n.t("activerecord.enums.request.status.#{status}", default: status.humanize)
  end

  # 에스크로 조회 메서드들 (외부 접근 필요)
  def trip_escrow
    escrow_transactions.find_by(escrow_type: "trip")
  end

  def detection_escrow
    escrow_transactions.find_by(escrow_type: "detection")
  end

  def construction_escrow
    escrow_transactions.find_by(escrow_type: "construction")
  end

  # 하위 호환성 (기존 코드 대응)
  def escrow_transaction
    construction_escrow || escrow_transactions.first
  end

  private

  def videos_content_type_and_size
    allowed_types = %w[video/mp4 video/quicktime video/avi video/x-msvideo video/webm video/3gpp video/3gpp2]
    videos.each do |video|
      unless allowed_types.include?(video.content_type)
        errors.add(:videos, "은 동영상 파일이어야 합니다 (MP4, MOV, AVI, WebM)")
      end
      if video.byte_size > 2.gigabytes
        errors.add(:videos, "는 2GB 이하여야 합니다")
      end
    end
  end

  def master_present?
    master.present?
  end

  def leak_confirmed?
    detection_leak_confirmed?
  end

  def has_estimates?
    estimates.exists?
  end

  def escrow_deposited_check?
    construction_escrow&.deposited? || trip_escrow&.deposited?
  end

  def release_escrow_payment
    self.closed_at = Time.current
    EscrowService.new(self).release_construction! if construction_escrow&.deposited?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status symptom_type building_type address customer_id master_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[customer master estimates]
  end
end
