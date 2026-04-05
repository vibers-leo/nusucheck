class VibersAdminController < ActionController::API
  before_action :verify_admin_secret

  def index
    stats = {
      totalUsers: User.count,
      contentCount: LeakInspection.count,
      mau: 0,
      recentSignups: User.where("created_at > ?", 7.days.ago).count
    }
    recent_activity = User.order(created_at: :desc).limit(5).map do |u|
      { id: u.id.to_s, type: "signup", label: u.email, timestamp: u.created_at }
    end
    render json: { projectId: "nusucheck", projectName: "누수체크", stats: stats, recentActivity: recent_activity, health: "healthy" }
  end

  def resource
    render json: [], status: :ok
  end

  private

  def verify_admin_secret
    unless request.headers["X-Vibers-Admin-Secret"] == ENV["VIBERS_ADMIN_SECRET"]
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
