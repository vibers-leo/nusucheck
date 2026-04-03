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
    @message.message_type ||= :user

    # 스티커 처리
    if params[:sticker_name].present?
      @message.message_category = :sticker
      @message.content = params[:sticker_name]
    else
      @message.message_category ||= :text
    end

    # Redis 기반 중복 전송 방지 (같은 유저가 같은 request에 0.5초 이내 재전송 차단)
    lock_key = "msg_lock:#{current_user.id}:#{@request.id}"
    if Rails.cache.read(lock_key)
      head :ok
      return
    end
    Rails.cache.write(lock_key, true, expires_in: 0.5.seconds)

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
    # 고객, 배정된 전문가, 어드민만 접근 가능
    return if current_user.admin?
    return if current_user.id == @request.customer_id
    return if current_user.id == @request.master_id

    # 아직 배정 안 된 전문가는 요청 상세 페이지로 안내
    if current_user.master?
      redirect_to masters_request_path(@request), alert: "배정 완료 후 채팅이 시작돼요."
    else
      redirect_to root_path, alert: "채팅 권한이 없어요."
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
