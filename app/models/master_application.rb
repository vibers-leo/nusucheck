class MasterApplication < ApplicationRecord
  belongs_to :request
  belongs_to :master, class_name: "Master"

  enum :status, { pending: 0, selected: 1, rejected: 2 }

  validates :request_id, uniqueness: { scope: :master_id, message: "이미 신청하셨습니다." }
  validates :intro_message, length: { maximum: 300 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
end
