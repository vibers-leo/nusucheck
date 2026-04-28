# frozen_string_literal: true

class Api::AiChatController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, raise: false

  ZEROCLAW_URL = ENV.fetch("ZEROCLAW_WEBHOOK_URL", "http://172.17.0.1:42627/webhook")

  def create
    message = params[:message].to_s.strip
    return render json: { reply: "메시지를 입력해주세요." } if message.blank?

    begin
      uri = URI(ZEROCLAW_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        message: message,
        user_id: current_user&.id,
        context: "nusucheck_chatbot"
      }.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body) rescue {}
        render json: { reply: data["reply"] || data["response"] || data["text"] || "답변을 준비 중이에요." }
      else
        render json: { reply: "AI 비서가 잠시 바쁜 것 같아요. 조금 뒤에 다시 시도해주세요." }
      end
    rescue => e
      Rails.logger.error "[AiChat] #{e.class}: #{e.message}"
      render json: { reply: "AI 비서 연결이 원활하지 않아요. 잠시 후 다시 시도해주세요." }
    end
  end
end
