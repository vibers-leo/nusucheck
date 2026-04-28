class FeedbacksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create], raise: false

  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.user = current_user if user_signed_in?

    if @feedback.save
      # 관리자에게 메일 발송
      ApplicationMailer.mail(
        to: ApplicationMailer::ADMIN_EMAILS,
        subject: "[누수체크] 의견 접수 - #{@feedback.category}",
        body: "이름: #{@feedback.name}\n이메일: #{@feedback.email}\n분류: #{@feedback.category}\n\n#{@feedback.message}"
      ).deliver_later rescue nil

      redirect_to root_path, notice: "소중한 의견 감사해요. 검토 후 연락드릴게요."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:name, :email, :category, :message)
  end
end
