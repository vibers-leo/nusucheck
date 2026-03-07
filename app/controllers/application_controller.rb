class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include HotwireNativeApp

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_customer, :current_master

  def current_customer
    current_user if current_user&.customer?
  end

  def current_master
    current_user if current_user&.master?
  end

  private

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
