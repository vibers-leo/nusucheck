class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_request
  before_action :check_chat_permission

  def index
    @messages = @request.messages.recent.includes(:sender)
    @message = Message.new

    # 상대방이 보낸 메시지 읽음 처리
    mark_unread_messages_as_read
  end

  def create
    @message = @request.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      # ActionCable을 통해 실시간 전송 (Message 모델의 after_create_commit에서 처리)

      # Turbo Stream 응답으로 메시지 추가
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to request_messages_path(@request) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { request: @request, message: @message }
          )
        end
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_request
    @request = Request.find(params[:request_id])
  end

  def check_chat_permission
    # 고객이거나 배정된 전문가만 접근 가능
    unless current_user.id == @request.customer_id || current_user.id == @request.master_id
      redirect_to root_path, alert: "채팅 권한이 없습니다."
    end
  end

  def message_params
    params.require(:message).permit(:content, images: [], videos: [])
  end

  def mark_unread_messages_as_read
    @request.messages
            .where.not(sender_id: current_user.id)
            .unread
            .update_all(read_at: Time.current)
  end
end
