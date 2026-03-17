class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :address, :type])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone, :address])
  end

  # 고객 전용 가입 - type을 Customer로 강제, 일반 가입은 registered 상태로 설정
  def build_resource(hash = {})
    hash[:type] = "Customer"
    hash[:account_status] = "registered"
    super
  end

  def after_sign_up_path_for(resource)
    customers_requests_path
  end
end
