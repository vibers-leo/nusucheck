class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.admin?
      # 관리자: 모든 채팅 확인 가능
      @requests = Request.where.not(status: :cancelled)
                         .includes(:customer, :master, :messages)
                         .order(updated_at: :desc)
    elsif current_user.customer?
      # 고객: 내 체크 중 채팅이 있는 것 (master 배정된 것 우선)
      @requests = current_user.requests
                              .where.not(status: :cancelled)
                              .includes(:master, :messages)
                              .order(updated_at: :desc)
    elsif current_user.master?
      # 전문가: 배정된 체크 + 신청 중인 체크
      @assigned = current_user.assigned_requests
                              .where.not(status: :cancelled)
                              .includes(:customer, :messages)
                              .order(updated_at: :desc)
      @applied = current_user.applied_requests
                             .where(status: :open)
                             .includes(:customer)
                             .order(updated_at: :desc)
      @requests = @assigned
    else
      @requests = Request.none
    end
  end
end
