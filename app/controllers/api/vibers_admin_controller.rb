class Api::VibersAdminController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  before_action :verify_admin_secret

  def index
    in_progress = defined?(Request) ? Request.where(status: %w[pending processing]).count : 0

    stats = {
      totalUsers: User.count,
      contentCount: defined?(Request) ? Request.count : 0,
      mau: 0,
      recentSignups: User.where("created_at > ?", 7.days.ago).count,
      inProgress: in_progress
    }

    recent_activity = User.order(created_at: :desc).limit(5).map do |u|
      { id: u.id.to_s, type: "signup", label: u.email, timestamp: u.created_at }
    end

    render json: {
      projectId: "nusucheck",
      projectName: "누수체크",
      stats: stats,
      recentActivity: recent_activity,
      health: "healthy"
    }
  end

  def resource
    case params[:resource]
    when "requests"
      model = defined?(LeakInspection) ? LeakInspection : (defined?(Request) ? Request : nil)
      if model
        data = model.order(created_at: :desc).limit(50).map do |r|
          { id: r.id.to_s, status: r.status, createdAt: r.created_at }
        end
        render json: data
      else
        render json: []
      end
    when "estimates"
      data = Estimate.order(created_at: :desc).limit(50).map do |e|
        { id: e.id.to_s, amount: e.amount, status: e.status, createdAt: e.created_at }
      end
      render json: data
    else
      render json: [], status: :ok
    end
  end

  private

  def verify_admin_secret
    unless request.headers["X-Vibers-Admin-Secret"] == ENV["VIBERS_ADMIN_SECRET"]
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
