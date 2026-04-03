class Admin::RequestsController < ApplicationController
  include AdminAccessible

  before_action :set_request, only: [:show, :publish, :assign_master, :close_no_charge, :finalize, :set_warranty, :resolve_complaint]

  def index
    @q = Request.ransack(params[:q])
    @requests = @q.result.includes(:customer, :master).recent.page(params[:page])
  end

  def show
    @available_masters = Master.joins(:master_profile)
                               .where(master_profiles: { verified: true })
                               .order(:name)
  end

  def publish
    authorize @request
    @request.publish!
    redirect_to admin_request_path(@request), notice: "공개 오더 풀에 등록했습니다. 전문가가 선택할 수 있습니다."
  rescue AASM::InvalidTransition => e
    redirect_to admin_request_path(@request), alert: "공개 등록 실패: #{e.message}"
  end

  def assign_master
    authorize @request
    master = Master.find(params[:master_id])
    @request.assign!(master: master)
    NotificationService.notify_request_assigned(@request) rescue nil

    # AI 시스템 메시지: 전문가 배정 완료
    SystemMessageService.send_master_assigned_message(@request, master)

    redirect_to admin_request_path(@request), notice: "#{master.name} 마스터가 직접 배정되었습니다."
  rescue AASM::InvalidTransition => e
    redirect_to admin_request_path(@request), alert: "마스터 배정 실패: #{e.message}"
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_request_path(@request), alert: "존재하지 않는 마스터입니다."
  end

  def close_no_charge
    authorize @request
    @request.close_no_charge!
    redirect_to admin_request_path(@request), notice: "비용 미청구로 종료되었습니다."
  rescue AASM::InvalidTransition => e
    redirect_to admin_request_path(@request), alert: "종료 실패: #{e.message}"
  end

  def finalize
    authorize @request
    @request.finalize!
    redirect_to admin_request_path(@request), notice: "최종 종료 처리되었습니다."
  rescue AASM::InvalidTransition => e
    redirect_to admin_request_path(@request), alert: "종료 실패: #{e.message}"
  end

  # ─── 하자보수 보증기간 설정 ──────────────────────────────────
  def set_warranty
    authorize @request, :finalize?
    months = params[:warranty_months].to_i
    if months > 0
      @request.set_warranty!(months)
      redirect_to admin_request_path(@request), notice: "하자보수 보증기간이 #{months}개월로 설정되었습니다."
    else
      redirect_to admin_request_path(@request), alert: "보증기간을 입력해주세요."
    end
  end

  # ─── 고객 불만 처리 ──────────────────────────────────────────
  def resolve_complaint
    authorize @request, :finalize?
    @request.update!(customer_complaint: nil, complaint_submitted_at: nil)
    redirect_to admin_request_path(@request), notice: "고객 불만이 처리 완료 처리되었습니다."
  end

  private

  def set_request
    @request = Request.includes(:customer, :master, :estimates, :escrow_transactions, :insurance_claims).find(params[:id])
  end
end
