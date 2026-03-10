class Masters::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_master!
  before_action :set_subscription

  def index
    # 구독 플랜 페이지
  end

  def upgrade
    new_tier = params[:tier]&.to_sym

    unless Subscription.tiers.keys.include?(new_tier.to_s)
      redirect_to masters_subscriptions_path, alert: "올바른 플랜이 아닙니다."
      return
    end

    # 현재 티어보다 낮은 티어로는 변경 불가 (downgrade는 별도 처리)
    current_tier_value = Subscription.tiers[@subscription.tier]
    new_tier_value = Subscription.tiers[new_tier.to_s]

    if new_tier_value < current_tier_value
      redirect_to masters_subscriptions_path, alert: "플랜 다운그레이드는 '다운그레이드' 버튼을 사용해주세요."
      return
    end

    # 같은 티어면 갱신
    if @subscription.tier == new_tier.to_s
      @subscription.renew!
      redirect_to masters_subscriptions_path, notice: "구독이 갱신되었습니다."
      return
    end

    # 업그레이드 처리
    @subscription.update!(
      tier: new_tier,
      starts_on: Date.current,
      expires_on: Date.current + 1.month,
      active: true
    )
    @subscription.set_monthly_fee_by_tier!
    @subscription.save!

    # Toss-like 축하 메시지
    tier_name = @subscription.features_for_tier[:display_name]
    redirect_to masters_subscriptions_path, notice: "🎉 #{tier_name}으로 업그레이드되었습니다! 더 많은 고객을 만나보세요."
  end

  def downgrade
    # Free 플랜으로만 다운그레이드 가능
    @subscription.update!(
      tier: :free,
      monthly_fee: 0,
      expires_on: 99.years.from_now,  # 무료 플랜은 만료 없음
      active: true
    )

    redirect_to masters_subscriptions_path, notice: "무료 플랜으로 전환되었습니다."
  end

  private

  def ensure_master!
    unless current_user.is_a?(Master)
      redirect_to root_path, alert: "전문가만 접근할 수 있습니다."
    end
  end

  def set_subscription
    @subscription = current_user.subscription || current_user.create_subscription!(
      tier: :free,
      monthly_fee: 0,
      starts_on: Date.current,
      expires_on: 99.years.from_now
    )
  end
end
