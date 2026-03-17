class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def home
  end

  def coming_soon
  end

  def about
  end

  def pricing
  end

  def how_it_works
    # 서비스 소개 페이지
  end

  def reviews
    # 리뷰/후기 페이지
    @reviews = Review.includes(:customer, :master, :request)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(12)

    # 필터
    if params[:rating].present?
      @reviews = @reviews.where(overall_rating: params[:rating])
    end

    if params[:symptom_type].present?
      @reviews = @reviews.joins(:request).where(requests: { symptom_type: params[:symptom_type] })
    end
  end

  def faq
    # FAQ/고객센터 페이지
  end

  def events
    # 이벤트/쿠폰 페이지
  end
end
