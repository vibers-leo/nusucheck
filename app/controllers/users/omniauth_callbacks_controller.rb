class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :kakao

  def kakao
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Kakao") if is_navigational_format?
    else
      session["devise.kakao_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: "카카오 로그인에 실패했습니다."
    end
  end

  def failure
    redirect_to root_path, alert: "카카오 로그인에 실패했습니다. 다시 시도해주세요."
  end
end
