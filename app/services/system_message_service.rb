class SystemMessageService
  def self.send_welcome_message(request)
    new(request).send_welcome_message
  end

  def self.send_video_received_message(request)
    new(request).send_video_received_message
  end

  def self.send_matching_in_progress_message(request)
    new(request).send_matching_in_progress_message
  end

  def self.send_expert_request_prompt(request)
    new(request).send_expert_request_prompt
  end

  def self.send_master_assigned_message(request, master)
    new(request).send_master_assigned_message(master)
  end

  def self.send_estimate_received_message(request)
    new(request).send_estimate_received_message
  end

  def self.send_construction_started_message(request)
    new(request).send_construction_started_message
  end

  def self.send_construction_completed_message(request)
    new(request).send_construction_completed_message
  end

  def initialize(request)
    @request = request
  end

  def send_welcome_message
    create_system_message(
      "안녕하세요! 👋\n누수 문제를 빠르게 해결해 드리겠습니다.\n\n" \
      "접수하신 내용을 검토하고 있어요."
    )
  end

  def send_video_received_message
    create_system_message(
      "✅ 사진/영상을 잘 받았어요!\n\n" \
      "전문가 매칭을 시작합니다."
    )
  end

  def send_matching_in_progress_message
    create_system_message(
      "🔍 전문가 매칭 중입니다...\n\n" \
      "고객님의 위치와 증상에 맞는 최적의 전문가를 찾고 있어요.\n" \
      "잠시만 기다려 주세요!"
    )
  end

  def send_master_assigned_message(master)
    create_system_message(
      "🔧 #{master.name} 전문가님과 연결되었습니다!\n\n" \
      "#{master.master_profile&.experience_years}년 경력 | " \
      "완료 건수 #{master.assigned_requests.where(status: :closed).count}건\n\n" \
      "이제 전문가님과 직접 대화하실 수 있어요."
    )
  end

  def send_estimate_received_message
    create_system_message(
      "📋 견적서가 도착했어요!\n\n" \
      "상세 내용을 확인하시고 진행 여부를 결정해 주세요."
    )
  end

  def send_expert_request_prompt
    create_system_message(
      "📋 잠깐, 기다리는 동안 사전진단을 해보세요!\n\n" \
      "증상, 건물 정보, 상황을 미리 입력해두면:\n" \
      "• 전문가가 배정됐을 때 훨씬 빠르게 진행돼요\n" \
      "• 더 정확한 견적을 받을 수 있어요\n\n" \
      "위쪽 파란색 배너의 [시작 →] 버튼을 눌러주세요!"
    )
  end

  def send_construction_started_message
    create_system_message(
      "🛠️ 공사가 시작되었습니다.\n\n" \
      "전문가님이 최선을 다해 작업하고 있어요.\n" \
      "완료까지 조금만 기다려 주세요!"
    )
  end

  def send_construction_completed_message
    create_system_message(
      "✨ 공사가 완료되었습니다!\n\n" \
      "작업 결과를 확인하시고 완료 확인 버튼을 눌러주세요.\n" \
      "리뷰를 남겨주시면 다른 고객들에게 큰 도움이 됩니다."
    )
  end

  private

  def create_system_message(content)
    message = ::Message.create!(
      request: @request,
      content: content,
      message_type: :system,
      sender: nil
    )

    # ActionCable 브로드캐스트는 after_create_commit에서 자동 처리됨
    message
  end
end
