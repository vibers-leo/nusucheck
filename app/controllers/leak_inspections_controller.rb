class LeakInspectionsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure_current_user, only: [:create]
  before_action :set_inspection, only: [:show]

  def new
    @inspection = LeakInspection.new
  end

  def create
    @inspection = LeakInspection.new(inspection_params)
    @inspection.customer = current_user_or_guest

    if @inspection.save
      # AI 분석 시작 (백그라운드)
      begin
        LeakInspectionService.new(@inspection).analyze!
      rescue LeakInspectionService::AnalysisError
        # 분석 실패는 무시하고 계속 진행
      end

      # Request 생성 (채팅방 연결)
      @request = create_request_from_inspection(@inspection)

      # 채팅방으로 리디렉션 (게스트도 접근 가능)
      redirect_to customers_request_path(@request), notice: "누수 체크가 접수되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  # 게스트가 아니면 자동 게스트 생성
  def ensure_current_user
    return if user_signed_in?
    guest = User.create_guest!
    session[:guest_user_id] = guest.id
  end

  def current_user_or_guest
    current_user || find_guest_user
  end

  def find_guest_user
    return nil unless session[:guest_user_id]
    User.find_by(id: session[:guest_user_id], account_status: :guest)
  end

  def create_request_from_inspection(inspection)
    request = Request.create!(
      customer: current_user_or_guest,
      symptom_type: inspection.symptom_type || :wall_leak,
      address: inspection.location_description || "미정",
      detection_result: :result_pending,
      status: :reported
    )

    # AI 환영 메시지 (Toss-like 친절한 톤)
    Message.create!(
      request: request,
      message_type: :system,
      content: <<~WELCOME.strip
        안녕하세요! 누수체크입니다 👋

        업로드하신 사진/영상을 AI가 분석 중이에요.
        분석이 완료되면 바로 알려드릴게요!

        🔍 분석 완료 후 진행 순서:
        1️⃣ AI 분석 결과 확인
        2️⃣ 주변 전문가와 자동 매칭
        3️⃣ 전문가와 채팅으로 상담
        4️⃣ 필요시 계정 만들기 (간편 로그인 가능)

        잠깐만 기다려주세요! 🤖
      WELCOME
    )

    # 추가 안내 메시지
    Message.create!(
      request: request,
      message_type: :system,
      content: "💡 지금은 로그인하지 않으셔도 돼요. 전문가와 매칭된 후 필요할 때 로그인하시면 됩니다!"
    )

    request
  end

  def set_inspection
    @inspection = if current_user.is_a?(Customer)
                    LeakInspection.find(params[:id])
                  else
                    LeakInspection.find_by!(id: params[:id], session_token: params[:token])
                  end
  end

  def inspection_params
    params.require(:leak_inspection).permit(:photo, :location_description, :symptom_type)
  end
end
