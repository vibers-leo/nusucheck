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

  # 메시지 카테고리 (채팅방 안에서 다양한 기능)
  enum message_category: {
    text: 0,              # 일반 텍스트
    estimate: 1,          # 견적서
    schedule: 2,          # 일정 제안
    payment_request: 3,   # 결제 요청
    payment_complete: 4,  # 결제 완료
    insurance_claim: 5,   # 보험청구서
    system_notice: 6,     # 시스템 알림
    sticker: 7            # 스티커
  }

  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }, unless: :sticker?
  validates :message_type, presence: true
  validates :metadata, presence: true, if: :structured_message?

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

  def structured_message?
    !text? && !system_notice?
  end

  # 견적서 메시지 생성 헬퍼
  def self.create_estimate_message!(request:, estimate:, sender:)
    create!(
      request: request,
      sender: sender,
      message_type: :user,
      message_category: :estimate,
      content: "견적서를 보냈습니다.",
      metadata: {
        estimate_id: estimate.id,
        amount: estimate.total_amount,
        breakdown: estimate.items.map { |item| { name: item.name, price: item.price } }
      }
    )
  end

  # 일정 제안 메시지 생성
  def self.create_schedule_message!(request:, proposed_date:, time_slot:, sender:)
    create!(
      request: request,
      sender: sender,
      message_type: :user,
      message_category: :schedule,
      content: "방문 일정을 제안했습니다.",
      metadata: {
        proposed_date: proposed_date,
        time_slot: time_slot,
        status: "pending"
      }
    )
  end

  # 결제 요청 메시지 생성
  def self.create_payment_request!(request:, amount:, payment_method:, sender:)
    create!(
      request: request,
      sender: sender,
      message_type: :user,
      message_category: :payment_request,
      content: "#{amount.to_s(:delimited)}원 결제를 요청합니다.",
      metadata: {
        amount: amount,
        payment_method: payment_method,  # "direct" or "escrow"
        status: "pending"
      }
    )
  end

  # 결제 완료 메시지 생성
  def self.create_payment_complete!(request:, amount:, transaction_id:)
    create!(
      request: request,
      sender: nil,
      message_type: :system,
      message_category: :payment_complete,
      content: "결제가 완료되었습니다.",
      metadata: {
        amount: amount,
        transaction_id: transaction_id,
        completed_at: Time.current.iso8601
      }
    )
  end

  # 보험청구서 메시지 생성
  def self.create_insurance_claim_message!(request:, insurance_claim:, sender:)
    create!(
      request: request,
      sender: sender,
      message_type: :user,
      message_category: :insurance_claim,
      content: "보험청구서가 준비되었습니다.",
      metadata: {
        claim_id: insurance_claim.id,
        document_url: Rails.application.routes.url_helpers.download_pdf_customers_insurance_claim_path(insurance_claim)
      }
    )
  end

  private

  def broadcast_message
    # ActionCable JSON으로 직접 broadcast — JS에서 sender_id로 내 메시지/상대 메시지 구분
    ActionCable.server.broadcast(
      "chat_#{request_id}",
      {
        type: "new_message",
        id: id,
        content: content,
        sender_name: sender_name,
        sender_id: sender_id,
        created_at: created_at.strftime("%H:%M")
      }
    )
  end
end
