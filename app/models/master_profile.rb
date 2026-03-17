class MasterProfile < ApplicationRecord
  SPECIALTY_OPTIONS = %w[수도배관 방수 욕실 옥상 바닥 외벽].freeze

  belongs_to :user, class_name: "Master", inverse_of: :master_profile

  validates :user_id, uniqueness: true
  validates :license_number, presence: true, if: :verified?
  validates :bank_name, :account_number, :account_holder, presence: true, if: :verified?
  validates :experience_years, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }

  def verify!
    update_columns(verified: true, verified_at: Time.current)
  end

  def reject!
    update_columns(verified: false, verified_at: nil)
  end

  def equipment_list
    equipment.is_a?(Array) ? equipment : []
  end

  def service_areas_list
    service_areas.is_a?(Array) ? service_areas : []
  end

  def specialty_types_list
    specialty_types.is_a?(Array) ? specialty_types : []
  end
end
