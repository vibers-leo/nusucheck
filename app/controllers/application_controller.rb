class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include HotwireNativeApp

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  helper_method :current_customer, :current_master

  def current_customer
    current_user if current_user&.customer?
  end

  def current_master
    current_user if current_user&.master?
  end

  private

  def record_not_found
    respond_to do |format|
      format.html do
        flash[:alert] = "요청하신 정보를 찾을 수 없습니다."
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "리소스를 찾을 수 없습니다." }, status: :not_found }
    end
  end

  def parameter_missing(exception)
    respond_to do |format|
      format.html do
        flash[:alert] = "필수 파라미터가 누락되었습니다: #{exception.param}"
        redirect_back(fallback_location: root_path)
      end
      format.json { render json: { error: "필수 파라미터 누락: #{exception.param}" }, status: :bad_request }
    end
  end

  def user_not_authorized
    flash[:alert] = "이 작업을 수행할 권한이 없습니다."
    redirect_back(fallback_location: root_path)
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.master?
      expert_dashboard_path  # 전문가 대시보드
    else
      customers_dashboard_path  # 고객 대시보드
    end
  end
end
