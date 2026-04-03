class Customers::ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_customer!

  def show
    @customer = current_user
  end

  def edit
    @customer = current_user
  end

  def update
    @customer = current_user

    if @customer.update(customer_params)
      redirect_to customers_profile_path, notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def unlink_social
    @customer = current_user

    unless @customer.encrypted_password.present?
      redirect_to customers_profile_path, alert: "비밀번호를 먼저 설정해야 소셜 로그인 연동을 해제할 수 있습니다."
      return
    end

    @customer.update!(provider: nil, uid: nil)
    redirect_to customers_profile_path, notice: "소셜 로그인 연동이 해제되었습니다."
  end

  private

  def customer_params
    params.require(:user).permit(:name, :phone, :address)
  end

  def ensure_customer!
    redirect_to root_path, alert: "고객만 접근 가능합니다." unless current_user.customer?
  end
end
