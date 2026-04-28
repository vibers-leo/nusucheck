class Customers::InsuranceClaimsController < ApplicationController
  include CustomerAccessible

  before_action :set_insurance_claim, only: [:show, :edit, :update, :submit_claim, :customer_approve, :customer_request_changes, :download_pdf, :start_review, :auto_submit]
  before_action :set_request, only: [:new, :create], if: -> { params[:request_id].present? }

  def index
    @q = current_user.insurance_claims.ransack(params[:q])
    @insurance_claims = @q.result.recent.page(params[:page])
  end

  def show
    authorize @insurance_claim
  end

  def new
    @insurance_claim = current_user.insurance_claims.build
    if @request
      @insurance_claim.request = @request
      @insurance_claim.prefill_from_request!
    end
  end

  def create
    @insurance_claim = current_user.insurance_claims.build(insurance_claim_params)
    @insurance_claim.request = @request if @request

    if @insurance_claim.save
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "보험 신청서가 저장되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @insurance_claim
  end

  def update
    authorize @insurance_claim
    if @insurance_claim.update(insurance_claim_params)
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "보험 신청서가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def submit_claim
    authorize @insurance_claim
    if @insurance_claim.may_submit_claim?
      @insurance_claim.submit_claim!
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "보험 신청이 완료되었습니다."
    else
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  alert: "현재 상태에서는 신청할 수 없습니다."
    end
  end

  def customer_approve
    authorize @insurance_claim
    if @insurance_claim.may_customer_approve?
      @insurance_claim.customer_approve!

      # 마스터에게 승인 알림 이메일 발송
      if @insurance_claim.prepared_by_master?
        InsuranceClaimMailerJob.perform_later("customer_approved", @insurance_claim.id)
        # 실시간 알림 발송
        NotificationService.notify_insurance_approved(@insurance_claim)
      end

      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "보험 신청서를 승인하고 제출했습니다."
    else
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  alert: "현재 상태에서는 승인할 수 없습니다."
    end
  end

  def customer_request_changes
    authorize @insurance_claim
    notes = params[:customer_review_notes]

    if @insurance_claim.may_customer_request_changes?
      @insurance_claim.customer_review_notes = notes
      @insurance_claim.customer_request_changes!

      # 마스터에게 수정 요청 알림 이메일 발송
      if @insurance_claim.prepared_by_master?
        InsuranceClaimMailerJob.perform_later("change_requested", @insurance_claim.id)
        # 실시간 알림 발송
        NotificationService.notify_insurance_change_requested(@insurance_claim)
      end

      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "전문가에게 수정 요청을 보냈습니다."
    else
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  alert: "현재 상태에서는 수정 요청을 할 수 없습니다."
    end
  end

  def download_pdf
    authorize @insurance_claim
    pdf = InsuranceClaimPdfService.new(@insurance_claim).generate
    send_data pdf.render,
              filename: "보험신청서_#{@insurance_claim.claim_number}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  # 사용자가 수동으로 보험사에 제출 완료 후 심사 시작
  def start_review
    authorize @insurance_claim

    if @insurance_claim.may_start_review?
      @insurance_claim.start_review!

      # 실시간 알림
      NotificationService.notify(
        recipient: @insurance_claim.customer,
        action: "insurance_under_review",
        message: "보험 청구서 심사가 시작되었습니다.",
        notifiable: @insurance_claim
      )

      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "심사 중 상태로 변경되었습니다. 보험사 심사 결과를 기다려주세요."
    else
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  alert: "현재 상태에서는 심사를 시작할 수 없습니다."
    end
  end

  # 보험사에 자동 제출 (이메일 발송)
  def auto_submit
    authorize @insurance_claim

    # 보험사 정보 확인
    if @insurance_claim.insurance_company.blank?
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  alert: "보험사를 먼저 선택해주세요."
      return
    end

    # 자동 제출 서비스 실행
    begin
      submission_service = InsuranceSubmissionService.new(@insurance_claim)

      if submission_service.submit_to_insurance_company!
        redirect_to customers_insurance_claim_path(@insurance_claim),
                    notice: "#{@insurance_claim.insurance_company}에 보험 청구서가 이메일로 발송됐어요."
      else
        errors = submission_service.errors.join(", ")
        redirect_to customers_insurance_claim_path(@insurance_claim),
                    alert: "자동 제출에 실패했어요: #{errors}"
      end
    rescue => e
      Rails.logger.error "[InsuranceClaim#auto_submit] #{e.class}: #{e.message}"
      redirect_to customers_insurance_claim_path(@insurance_claim),
                  notice: "보험 신청서가 저장됐어요. 관리자가 확인 후 처리해드릴게요."
    end
  end

  private

  def set_insurance_claim
    @insurance_claim = current_user.insurance_claims.find(params[:id])
  end

  def set_request
    @request = current_user.requests.find_by!(public_token: params[:request_id])
  end

  def insurance_claim_params
    params.require(:insurance_claim).permit(
      :applicant_name, :applicant_phone, :applicant_email,
      :birth_date, :incident_address, :incident_detail_address,
      :incident_date, :incident_description, :damage_type,
      :estimated_damage_amount, :insurance_company, :policy_number,
      :victim_name, :victim_phone, :victim_address,
      supporting_documents: []
    )
  end
end
