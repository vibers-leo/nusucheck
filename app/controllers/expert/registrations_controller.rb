class Expert::RegistrationsController < Devise::RegistrationsController
  layout "expert"
  before_action :configure_sign_up_params, only: [:create]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :name, :phone, :address, :type,
      master_profile_attributes: [
        :experience_years, :bio,
        specialty_types: [],
        service_areas: []
      ]
    ])
  end

  # 전문가(마스터)로 강제 설정, registered 상태로 설정
  def build_resource(hash = {})
    hash[:type] = "Master"
    hash[:account_status] = "registered"
    super
  end

  def after_sign_up_path_for(resource)
    # 관리자에게 새 전문가 가입 알림
    User.where(role: :admin).each do |admin|
      NotificationService.notify(
        recipient: admin,
        action: "new_master_signup",
        message: "새 전문가 #{resource.name}님이 가입했습니다. 프로필을 검토하고 승인해주세요.",
        notifiable: resource
      )
    end rescue nil
    edit_masters_profile_path
  end

  def after_inactive_sign_up_path_for(resource)
    expert_root_path
  end
end
