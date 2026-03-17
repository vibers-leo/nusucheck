class ChatChannel < ApplicationCable::Channel
  def subscribed
    request = Request.find(params[:request_id])

    # 권한 확인: 고객 또는 배정된 전문가만 채팅 가능
    if can_access_chat?(request)
      stream_from "chat_#{request.id}"

      # 입장 시 상대방 메시지 읽음 처리 + 읽음 브로드캐스트
      mark_messages_as_read(request)
      broadcast_read_receipt(request)
    else
      reject
    end
  end

  def unsubscribed
    # 퇴장 시 타이핑 인디케이터 제거
    begin
      request = Request.find(params[:request_id])
      ActionCable.server.broadcast("chat_#{request.id}", {
        type: "typing",
        user_id: current_user&.id,
        user_name: current_user&.name,
        typing: false
      })
    rescue ActiveRecord::RecordNotFound
      # 무시
    end
  end

  def speak(data)
    request = Request.find(params[:request_id])
    return unless can_access_chat?(request)

    message = request.messages.create!(
      sender: current_user,
      content: data["message"]
    )

    # 알림 전송 (상대방에게) — 상대방이 현재 채팅방에 없을 때만
    recipient = (request.customer_id == current_user.id) ? request.master : request.customer
    if recipient.present?
      NotificationService.notify(
        recipient: recipient,
        action: "new_message",
        message: "#{current_user.name}님이 메시지를 보냈습니다: #{message.content.truncate(30)}",
        notifiable: request
      )
    end
  end

  # 타이핑 인디케이터 브로드캐스트
  def typing(data)
    request = Request.find(params[:request_id])
    return unless can_access_chat?(request)

    ActionCable.server.broadcast("chat_#{request.id}", {
      type: "typing",
      user_id: current_user.id,
      user_name: current_user.name,
      typing: data["typing"] == true
    })
  end

  # 읽음 처리 (클라이언트에서 명시적으로 호출 가능)
  def mark_read(data)
    request = Request.find(params[:request_id])
    return unless can_access_chat?(request)

    mark_messages_as_read(request)
    broadcast_read_receipt(request)
  end

  private

  def can_access_chat?(request)
    return false unless current_user
    current_user.id == request.customer_id || current_user.id == request.master_id
  end

  def mark_messages_as_read(request)
    request.messages
           .where.not(sender_id: current_user.id)
           .unread
           .update_all(read_at: Time.current)
  end

  def broadcast_read_receipt(request)
    ActionCable.server.broadcast("chat_#{request.id}", {
      type: "read_receipt",
      reader_id: current_user.id
    })
  end
end
