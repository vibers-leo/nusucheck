class Masters::ProfilesController < ApplicationController
  include MasterAccessible

  before_action :set_profile

  def show
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to masters_profile_path, notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 보험가입증명서 업로드 + OCR 자동 파싱
  def upload_insurance
    file = params[:insurance_certificate]

    unless file.present?
      redirect_to masters_insurance_verification_path, alert: "파일을 선택해주세요." and return
    end

    @profile.insurance_certificate.attach(file)

    # OCR 파싱 (키가 없으면 수동 검토로 전환)
    ocr_result = if InsuranceOcrService.configured?
      image_url = url_for(@profile.insurance_certificate)
      InsuranceOcrService.new(image_url).call
    else
      { success: false, error: "OCR 서비스 미설정" }
    end

    if ocr_result[:success]
      @profile.update!(
        insurance_pending_review: true,
        insurance_ocr_data: ocr_result,
        insurance_insurer_name: ocr_result[:insurer_name],
        insurance_valid_until: ocr_result[:valid_until],
        insurance_verified: false
      )
    else
      # OCR 없이도 파일은 저장 → 관리자 수동 검토
      @profile.update!(
        insurance_pending_review: true,
        insurance_ocr_data: { source: "manual_upload", uploaded_at: Time.current },
        insurance_verified: false
      )
    end

    NotificationService.notify_admins(
      action: "insurance_review_requested",
      message: "#{current_user.name}님이 보험증명서를 업로드했어요. 검토가 필요해요.",
      notifiable: @profile
    ) rescue nil

    redirect_to masters_insurance_verification_path,
      notice: "보험증명서가 제출됐어요! 관리자 검토 후 인증이 완료돼요."
  end

  private

  def set_profile
    @profile = current_user.master_profile || current_user.create_master_profile
  end

  def profile_params
    params.require(:master_profile).permit(
      :license_number, :license_type, :experience_years,
      :bank_name, :account_number, :account_holder, :bio,
      equipment: [], service_areas: []
    )
  end
end
