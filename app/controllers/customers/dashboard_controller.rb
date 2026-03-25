class Customers::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_customer!

  def index
    # 진행 중인 체크 (완료/취소 제외)
    @active_requests = current_user.requests
                                   .where.not(status: %w[closed cancelled])
                                   .order(created_at: :desc)
                                   .limit(5)

    # 견적 대기 중
    @pending_estimates = current_user.requests
                                     .where(status: %w[estimate_pending estimate_submitted])
                                     .order(created_at: :desc)

    # 최근 완료된 체크
    @recent_completed = current_user.requests
                                    .where(status: :closed)
                                    .order(closed_at: :desc)
                                    .limit(3)

    # 이번 달 체크 접수 수
    @monthly_requests_count = current_user.requests
                                          .where(created_at: Time.current.beginning_of_month..)
                                          .count

    # 이번 달 지출 총액
    @monthly_total_spent = current_user.escrow_transactions
                                       .where(status: %w[released settled])
                                       .where(created_at: Time.current.beginning_of_month..)
                                       .sum(:amount)

    # 리뷰 작성 가능한 체크
    @reviewable_requests = current_user.requests
                                       .where(status: :closed)
                                       .where.missing(:review)
                                       .order(closed_at: :desc)
                                       .limit(3)

    # 최근 알림
    @recent_notifications = current_user.notifications
                                        .order(created_at: :desc)
                                        .limit(5)
  end

  private

  def ensure_customer!
    unless current_user.can_access_customer?
      redirect_to root_path, alert: "고객 권한이 필요합니다."
    end
  end
end
