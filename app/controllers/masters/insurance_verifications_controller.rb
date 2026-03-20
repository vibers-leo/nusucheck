class Masters::InsuranceVerificationsController < ApplicationController
  include MasterAccessible

  before_action :set_profile

  # GET /masters/insurance_verification
  # 인증 방법 선택 화면 (OCR vs CODEF 자동조회)
  def show
  end

  # POST /masters/insurance_verification/request_auth
  # CODEF 간편인증 요청 → 사용자 휴대폰으로 PASS/카카오 알림 발송
  def request_auth
    unless CodefConfig.available?
      redirect_to masters_insurance_verification_path, alert: "자동 조회 서비스가 준비 중이에요. 증명서 업로드를 이용해주세요." and return
    end

    user_info = {
      name:       params[:name],
      birth:      params[:birth_date]&.gsub(/[^0-9]/, ""),
      phone:      params[:phone]&.gsub(/[^0-9]/, ""),
      telecom:    params[:telecom],
      login_type: params[:login_type]&.to_sym || :pass
    }

    if user_info[:name].blank? || user_info[:birth].blank? || user_info[:phone].blank?
      redirect_to masters_insurance_verification_path, alert: "이름, 생년월일, 전화번호를 모두 입력해주세요." and return
    end

    result = CodefInsuranceService.new.request_auth(user_info)

    if result[:success] && result[:done]
      # Sandbox에서 즉시 완료되는 케이스
      handle_success(result[:contracts])
    elsif result[:success] && !result[:done]
      # 휴대폰 인증 대기 중
      session[:codef_job_id]   = result[:job_id]
      session[:codef_user_name]  = user_info[:name]
      session[:codef_user_birth] = user_info[:birth]
      session[:codef_user_phone] = user_info[:phone]
      redirect_to waiting_masters_insurance_verification_path
    else
      redirect_to masters_insurance_verification_path, alert: result[:error]
    end
  end

  # GET /masters/insurance_verification/waiting
  # 사용자 휴대폰 인증 대기 화면 (JS 자동 폴링)
  def waiting
    unless session[:codef_job_id].present?
      redirect_to masters_insurance_verification_path and return
    end
  end

  # GET /masters/insurance_verification/poll (JSON)
  # 인증 완료 여부 확인 (JS에서 주기적으로 호출)
  def poll
    job_id = session[:codef_job_id]

    unless job_id.present?
      render json: { done: false, error: "세션이 만료됐어요. 다시 시도해주세요." } and return
    end

    user_info = {
      name:  session[:codef_user_name],
      birth: session[:codef_user_birth],
      phone: session[:codef_user_phone]
    }

    result = CodefInsuranceService.new.poll_result(job_id, user_info)

    if result[:success] && result[:done]
      # 인증 완료 → 보험 저장
      liability = result[:contracts].select { |c| c[:has_liability] }
      best = liability.first || result[:contracts].first

      @profile.update!(
        insurance_verified: true,
        insurance_verified_at: Time.current,
        insurance_pending_review: false,
        insurance_insurer_name: best&.fetch(:insurer_name),
        insurance_valid_until: best&.fetch(:valid_until),
        insurance_ocr_data: { source: "codef", contracts: result[:contracts] }
      )

      clear_codef_session
      render json: { done: true, redirect_url: masters_profile_path }
    elsif result[:success] && !result[:done]
      render json: { done: false, message: result[:message] }
    else
      clear_codef_session
      render json: { done: false, error: result[:error] }
    end
  end

  private

  def set_profile
    @profile = current_user.master_profile || current_user.create_master_profile
  end

  def handle_success(contracts)
    liability = contracts.select { |c| c[:has_liability] }
    best = liability.first || contracts.first

    if best.nil?
      redirect_to masters_insurance_verification_path,
        alert: "배상책임보험이 확인되지 않았어요. 해당 보험에 가입되어 있는지 확인해주세요."
      return
    end

    @profile.update!(
      insurance_verified: true,
      insurance_verified_at: Time.current,
      insurance_pending_review: false,
      insurance_insurer_name: best[:insurer_name],
      insurance_valid_until: best[:valid_until],
      insurance_ocr_data: { source: "codef", contracts: contracts }
    )

    redirect_to masters_profile_path, notice: "배상책임보험 인증이 완료됐어요! 🎉"
  end

  def clear_codef_session
    session.delete(:codef_job_id)
    session.delete(:codef_user_name)
    session.delete(:codef_user_birth)
    session.delete(:codef_user_phone)
  end
end
