class Admin::MastersController < ApplicationController
  include AdminAccessible

  before_action :set_master, only: [:show, :verify, :reject, :approve_insurance, :reject_insurance]

  def index
    @q = Master.ransack(params[:q])
    @masters = @q.result.includes(:master_profile, :reviews).page(params[:page])
  end

  def show
    @profile = @master.master_profile
    @recent_requests = @master.assigned_requests.includes(:customer, :escrow_transactions).recent.limit(10)
    @reviews = @master.reviews.recent.limit(5)
  end

  def verify
    @master.master_profile.verify!
    redirect_to admin_master_path(@master), notice: "#{@master.name} 마스터가 인증되었습니다."
  end

  def reject
    @master.master_profile.reject!
    redirect_to admin_master_path(@master), notice: "#{@master.name} 마스터 인증이 거부되었습니다."
  end

  def approve_insurance
    profile = @master.master_profile
    ocr_data = profile.insurance_ocr_data&.symbolize_keys || {}
    ocr_data[:valid_until] = Date.parse(ocr_data[:valid_until].to_s) rescue nil
    profile.approve_insurance!(ocr_data)

    NotificationService.notify(
      recipient: @master,
      action: "insurance_approved",
      message: "배상책임보험 인증이 완료됐어요! 프로필에 보험 인증 뱃지가 표시돼요.",
      notifiable: profile
    ) rescue nil

    redirect_to admin_master_path(@master), notice: "#{@master.name} 마스터 보험 인증이 승인됐어요."
  end

  def reject_insurance
    @master.master_profile.reject_insurance!

    NotificationService.notify(
      recipient: @master,
      action: "insurance_rejected",
      message: "보험 인증 서류를 확인하지 못했어요. 선명한 보험가입증명서로 다시 제출해주세요.",
      notifiable: @master.master_profile
    ) rescue nil

    redirect_to admin_master_path(@master), alert: "#{@master.name} 마스터 보험 인증이 거절됐어요."
  end

  private

  def set_master
    @master = Master.find(params[:id])
  end
end
