class Admin::DashboardController < ApplicationController
  include AdminAccessible

  def index
    # === 기본 통계 (5분 캐시) ===
    # 자주 변경되지만 실시간일 필요는 없는 데이터
    @total_requests = Rails.cache.fetch("admin:total_requests", expires_in: 5.minutes) do
      Request.count
    end

    @active_requests = Rails.cache.fetch("admin:active_requests", expires_in: 5.minutes) do
      Request.active.count
    end

    @total_masters = Rails.cache.fetch("admin:total_masters", expires_in: 5.minutes) do
      Master.count
    end

    @verified_masters = Rails.cache.fetch("admin:verified_masters", expires_in: 5.minutes) do
      MasterProfile.verified.count
    end

    @pending_escrows = Rails.cache.fetch("admin:pending_escrows", expires_in: 5.minutes) do
      EscrowTransaction.where(status: "deposited").count
    end

    @revenue = Rails.cache.fetch("admin:total_revenue", expires_in: 5.minutes) do
      EscrowTransaction.where(status: ["released", "settled"]).sum(:platform_fee)
    end

    @total_insurance_claims = Rails.cache.fetch("admin:total_insurance_claims", expires_in: 5.minutes) do
      InsuranceClaim.count
    end

    @pending_insurance_claims = Rails.cache.fetch("admin:pending_insurance_claims", expires_in: 5.minutes) do
      InsuranceClaim.where(status: ["draft", "pending_customer_review"]).count
    end

    @submitted_insurance_claims = Rails.cache.fetch("admin:submitted_insurance_claims", expires_in: 5.minutes) do
      InsuranceClaim.where(status: "submitted").count
    end

    @completed_count = Rails.cache.fetch("admin:completed_count", expires_in: 5.minutes) do
      Request.where(status: "closed").count
    end

    # === 차트 데이터 (10분 캐시) ===
    # 계산 비용이 높은 시계열 데이터
    @weekly_requests = Rails.cache.fetch("admin:weekly_requests", expires_in: 10.minutes) do
      Request.where("created_at >= ?", 7.days.ago)
             .group("DATE(created_at)")
             .order("DATE(created_at)")
             .count
    end

    @monthly_requests = Rails.cache.fetch("admin:monthly_requests", expires_in: 10.minutes) do
      Request.where("created_at >= ?", 30.days.ago)
             .group("DATE(created_at)")
             .order("DATE(created_at)")
             .count
    end

    # === 수익 분석 (1시간 캐시) ===
    # 변경 빈도가 낮고 계산 비용이 높은 데이터
    @monthly_revenue = Rails.cache.fetch("admin:monthly_revenue", expires_in: 1.hour) do
      EscrowTransaction.where(
        status: ["released", "settled"],
        created_at: 6.months.ago..Time.current
      )
      .group(Arel.sql("TO_CHAR(created_at, 'YYYY-MM')"))
      .order(Arel.sql("TO_CHAR(created_at, 'YYYY-MM')"))
      .sum(:platform_fee)
    end

    @symptom_distribution = Rails.cache.fetch("admin:symptom_distribution", expires_in: 1.hour) do
      Request.group(:symptom_type).count
    end

    # === 실시간 데이터 (캐시 안함) ===
    # 관리자가 즉시 확인해야 하는 최신 데이터
    @recent_requests = Request.recent.limit(10)
    @recent_insurance_claims = InsuranceClaim.recent.limit(5)
    @pending_masters = Master.joins(:master_profile)
                             .where(master_profiles: { verified: false })
                             .includes(:master_profile)
                             .order(created_at: :desc)
  end
end
