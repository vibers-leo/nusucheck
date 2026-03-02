class MastersController < ApplicationController
  # 비로그인 고객도 볼 수 있는 전문가 공개 프로필
  skip_before_action :authenticate_user!, raise: false

  def index
    # 인증된 전문가만 표시
    base_scope = Master.joins(:master_profile)
                       .where(master_profiles: { verified: true })

    # 서비스 지역 필터
    if params[:service_area].present?
      base_scope = base_scope.where(
        "master_profiles.service_areas::text ILIKE ?",
        "%#{params[:service_area]}%"
      )
    end

    # 전문 분야 필터
    if params[:specialty].present?
      base_scope = base_scope.where(
        "master_profiles.specialty_types::text ILIKE ?",
        "%#{params[:specialty]}%"
      )
    end

    # Ransack 검색
    @q = base_scope.ransack(params[:q])

    # 평점순 정렬 + 페이지네이션
    @masters = @q.result
                 .includes(:master_profile, :reviews)
                 .select("users.*, AVG(reviews.overall_rating) as avg_rating, COUNT(DISTINCT reviews.id) as review_count")
                 .left_joins(:reviews)
                 .group("users.id, master_profiles.id")
                 .order("avg_rating DESC NULLS LAST")
                 .page(params[:page])
                 .per(12)
  end

  def show
    @master = Master.includes(:master_profile, :reviews).find(params[:id])
    @profile = @master.master_profile

    # 완료된 작업에서 사진 모아오기 (최근 12개)
    @completed_requests = @master.assigned_requests
                                 .where(status: "closed")
                                 .where.not(photos_count: 0)
                                 .order(closed_at: :desc)
                                 .limit(12)

    # 최근 리뷰 (최근 10개)
    @reviews = @master.reviews.includes(:request)
                      .order(created_at: :desc)
                      .limit(10)

    @avg_rating   = @master.average_rating
    @review_count = @master.reviews.count
    @completed_count = @master.assigned_requests.where(status: "closed").count
  end
end
