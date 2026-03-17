class LeakInspection < ApplicationRecord
  belongs_to :customer, class_name: "Customer", optional: true

  has_one_attached :photo

  validates :photo, presence: true
  validate :photo_size_and_type, if: -> { photo.attached? }

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp video/mp4 video/quicktime video/x-msvideo video/avi video/mov].freeze
  MAX_FILE_SIZE = 100.megabytes
  validates :session_token, presence: true, uniqueness: true

  before_validation :generate_session_token, on: :create

  enum :status, {
    pending: "pending",
    analyzing: "analyzing",
    completed: "completed",
    failed: "failed"
  }

  enum :severity, {
    none: "none",
    low: "low",
    medium: "medium",
    high: "high",
    critical: "critical"
  }, prefix: :severity

  enum :symptom_type, {
    wall_leak: 0,
    ceiling_leak: 1,
    floor_leak: 2,
    pipe_leak: 3,
    toilet_leak: 4,
    outdoor_leak: 5
  }

  scope :recent, -> { order(created_at: :desc) }

  def severity_label
    { "none" => "누수 없음", "low" => "경미", "medium" => "보통",
      "high" => "심각", "critical" => "매우 심각" }[severity] || "분석 중"
  end

  def severity_color
    { "none" => "green", "low" => "yellow", "medium" => "orange",
      "high" => "red", "critical" => "red" }[severity] || "gray"
  end

  def symptom_type_label
    { "wall_leak" => "벽면 누수", "ceiling_leak" => "천장 누수",
      "floor_leak" => "바닥 누수", "pipe_leak" => "배관 누수",
      "toilet_leak" => "화장실 누수", "outdoor_leak" => "외부 누수" }[symptom_type]
  end

  private

  def photo_size_and_type
    if photo.blob.byte_size > MAX_FILE_SIZE
      errors.add(:photo, "파일 크기는 100MB를 초과할 수 없습니다")
    end
    unless ALLOWED_CONTENT_TYPES.include?(photo.blob.content_type)
      errors.add(:photo, "이미지(JPG, PNG) 또는 영상(MP4, MOV, AVI) 파일만 업로드할 수 있습니다")
    end
  end

  def generate_session_token
    self.session_token ||= SecureRandom.urlsafe_base64(32)
  end
end
