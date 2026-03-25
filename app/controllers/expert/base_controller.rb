class Expert::BaseController < ApplicationController
  layout "expert"

  private

  def ensure_master!
    unless user_signed_in?
      flash[:alert] = "로그인이 필요합니다."
      redirect_to new_user_session_path
      return
    end
    unless current_user.can_access_master?
      flash[:alert] = "전문가 전용 페이지입니다."
      redirect_to expert_root_path
    end
  end
end
