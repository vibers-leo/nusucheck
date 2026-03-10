class User < ApplicationRecord
  # Devise 모듈 (게스트 지원을 위해 :validatable 제거, :omniauthable 추가)
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :omniauthable, omniauth_providers: [:kakao]

  # Associations
  has_many :notifications, as: :recipient, dependent: :destroy
  has_many :user_coupons, dependent: :destroy
  has_many :coupons, through: :user_coupons

  # 게스트 계정 상태
  enum account_status: {
    guest: 0,           # 임시 계정 (이메일/비밀번호 없음)
    registered: 1,      # 이메일/비밀번호 등록 완료
    verified: 2         # 전화번호 인증 완료 (선택)
  }

  # 조건부 검증
  validates :email, presence: true, uniqueness: true, if: :registered_or_verified?
  validates :password, presence: true, if: :password_required?
  validates :name, presence: true, if: :registered_or_verified?
  validates :phone, format: { with: /\A01[016789]-?\d{3,4}-?\d{4}\z/, allow_blank: true }, if: :phone_present?

  before_create :set_guest_token, if: :guest?

  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? }

  scope :customers, -> { where(type: "Customer") }
  scope :masters, -> { where(type: "Master") }
  scope :admins, -> { where(role: :admin) }

  enum :role, { user: 0, admin: 1 }

  # 게스트 계정 생성
  def self.create_guest!
    create!(
      account_status: :guest,
      email: nil,
      encrypted_password: "",
      type: "Customer"  # 게스트는 기본적으로 고객
    )
  end

  # 게스트 → 등록 회원 전환
  def upgrade_to_registered!(email:, password:, name: nil)
    update!(
      account_status: :registered,
      email: email,
      password: password,
      name: name || "고객#{id}"
    )
  end

  # 카카오 OAuth
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.nickname || "카카오유저#{SecureRandom.hex(4)}"
      user.type = "Customer"  # 기본 고객으로 생성
      user.account_status = :registered
    end
  end

  # Devise 오버라이드
  def email_required?
    registered_or_verified?
  end

  def password_required?
    return false if guest?
    !persisted? || password.present? || password_confirmation.present?
  end

  def customer?
    type == "Customer"
  end

  def master?
    type == "Master"
  end

  def admin_user?
    admin?
  end

  def display_role
    return "관리자" if admin?
    return "마스터" if master?
    "고객"
  end

  private

  def set_guest_token
    self.guest_token = SecureRandom.urlsafe_base64(32)
  end

  def registered_or_verified?
    registered? || verified?
  end

  def phone_present?
    phone.present?
  end
end
