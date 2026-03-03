class Message < ApplicationRecord
  belongs_to :request
  belongs_to :sender, class_name: "User", optional: true

  # 이미지/영상 첨부
  has_many_attached :images
  has_many_attached :videos

  # 메시지 타입: user(고객/전문가), system(AI 자동), admin(관리자 수동)
  enum message_type: {
    user: 0,
    system: 1,
    admin: 2
  }

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  validates :message_type, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :unread, -> { where(read_at: nil) }
  scope :for_request, ->(request_id) { where(request_id: request_id) }
  scope :user_messages, -> { where(message_type: :user) }
  scope :system_messages, -> { where(message_type: :system) }

  after_create_commit -> { broadcast_message }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update(read_at: Time.current) unless read?
  end

  def sender_name
    return "누수체크 AI" if system?
    return "관리자" if admin?
    sender&.name || "Unknown"
  end

  def sent_by_customer?
    user? && request.customer_id == sender_id
  end

  def sent_by_master?
    user? && request.master_id == sender_id
  end

  def system_message?
    system? || admin?
  end

  private

  def broadcast_message
    ActionCable.server.broadcast(
      "chat_#{request_id}",
      {
        id: id,
        content: content,
        sender_name: sender_name,
        sender_id: sender_id,
        sent_by_customer: sent_by_customer?,
        created_at: created_at.strftime("%H:%M"),
        html: ApplicationController.renderer.render(
          partial: "messages/message",
          locals: { message: self, current_user: sender }
        )
      }
    )
  end
end
