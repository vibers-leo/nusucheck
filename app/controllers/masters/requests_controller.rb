class Masters::RequestsController < ApplicationController
  include MasterAccessible

  before_action :set_request, only: [
    :show, :apply, :claim, :visit, :arrive, :detection_complete, :detection_fail,
    :submit_estimate, :start_construction, :complete_construction
  ]

  def index
    @q = current_user.assigned_requests.ransack(params[:q])
    @requests = @q.result.recent.page(params[:page])
    @open_count = Request.open_orders.count
    @needs_action_count = current_user.assigned_requests
                                      .where(status: %w[detecting estimate_pending])
                                      .count
  end

  def open_orders
    # 미승인 전문가 접근 차단
    unless current_user.master_profile&.verified?
      redirect_to masters_requests_path,
                  alert: "관리자 승인 후 공개 오더를 선택할 수 있습니다."
      return
    end

    base_scope = Request.open_orders

    # 내 지역 필터 (my_area=1 파라미터 또는 기본값)
    @my_areas = current_user.master_profile&.service_areas_list || []
    @filter_my_area = params[:my_area] == "1"

    if @filter_my_area && @my_areas.any?
      # service_areas_list에 포함된 지역 주소가 address에 포함된 오더만 필터
      area_conditions = @my_areas.map { |area| "requests.address ILIKE ?" }.join(" OR ")
      area_values     = @my_areas.map { |area| "%#{area}%" }
      base_scope = base_scope.where(area_conditions, *area_values)
    end

    @q = base_scope.ransack(params[:q])
    @requests = @q.result.includes(:customer).recent.page(params[:page])
  end

  # 자동 배정: 전문가가 신청하면 선착순으로 즉시 배정
  def apply
    unless current_user.master_profile&.verified?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash_messages", partial: "shared/flash_messages", locals: { alert: "승인된 전문가만 신청할 수 있습니다." }) }
        format.html { redirect_to open_orders_masters_requests_path, alert: "승인된 전문가만 신청할 수 있습니다." }
      end
      return
    end

    unless @request.open?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash_messages", partial: "shared/flash_messages", locals: { alert: "신청 가능한 상태가 아닙니다." }) }
        format.html { redirect_to open_orders_masters_requests_path, alert: "신청 가능한 상태가 아닙니다." }
      end
      return
    end

    @application = @request.master_applications.build(
      master: current_user,
      intro_message: params[:intro_message].to_s.strip.presence || "안녕하세요! 빠르게 방문 가능합니다."
    )

    if @application.save
      ActiveRecord::Base.transaction do
        @request.reload  # 동시 신청 race condition 방지
        raise AASM::InvalidTransition.new(@request, :claim) unless @request.may_claim?
        @request.claim!(master: current_user)
        @application.update!(status: :selected)
      end
      begin
        SystemMessageService.send_master_assigned_message(@request, current_user)
      rescue => e
        Rails.logger.error "[Masters::Requests#claim] SystemMessage 실패: #{e.message}"
      end
      begin
        NotificationService.notify_request_assigned(@request)
      rescue => e
        Rails.logger.error "[Masters::Requests#claim] Notification 실패: #{e.message}"
      end
      redirect_to masters_request_path(@request), notice: "오더가 배정됐어요! 방문 일정을 잡아주세요."
    else
      error_msg = @application.errors.full_messages.first || "신청 중 오류가 발생했습니다."
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash_messages", partial: "shared/flash_messages", locals: { alert: error_msg }) }
        format.html { redirect_to open_orders_masters_requests_path, alert: error_msg }
      end
    end
  rescue AASM::InvalidTransition
    @application&.update!(status: :rejected) rescue nil
    redirect_to open_orders_masters_requests_path, alert: "이미 다른 전문가가 먼저 배정된 오더예요."
  rescue ActiveRecord::RecordInvalid
    redirect_to open_orders_masters_requests_path, alert: "처리 중 오류가 발생했습니다."
  end

  def claim
    # 미승인 전문가 접근 차단
    unless current_user.master_profile&.verified?
      redirect_to open_orders_masters_requests_path,
                  alert: "승인된 전문가만 오더를 선택할 수 있습니다."
      return
    end

    authorize @request
    ActiveRecord::Base.transaction do
      @request.reload  # 선착순 경쟁 방지
      raise AASM::InvalidTransition.new(@request, :claim) unless @request.may_claim?
      @request.claim!(master: current_user)
    end
    NotificationService.notify_request_assigned(@request) rescue nil
    redirect_to masters_request_path(@request), notice: "오더를 수락했습니다! 방문 일정을 잡아주세요."
  rescue AASM::InvalidTransition
    redirect_to open_orders_masters_requests_path, alert: "이미 다른 전문가가 선택한 오더입니다."
  rescue ActiveRecord::RecordInvalid
    redirect_to open_orders_masters_requests_path, alert: "처리 중 오류가 발생했습니다."
  end

  def show
    authorize @request
  end

  def visit
    authorize @request
    @request.visit!
    redirect_to masters_request_path(@request), notice: "방문을 시작했습니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  def arrive
    authorize @request
    @request.arrive!
    redirect_to masters_request_path(@request), notice: "현장에 도착했습니다. 탐지를 시작합니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  def detection_complete
    authorize @request
    @request.update!(detection_result: :leak_confirmed, detection_notes: params[:detection_notes])
    @request.detection_complete!
    redirect_to masters_request_path(@request), notice: "누수가 확인되었습니다. 견적을 작성해주세요."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  def detection_fail
    authorize @request
    @request.detection_fail!
    redirect_to masters_request_path(@request), notice: "누수가 확인되지 않았습니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  def submit_estimate
    authorize @request
    @request.submit_estimate!
    @request.estimates.where(status: :pending).find_each do |est|
      NotificationService.notify_estimate_submitted(est) rescue nil
    end
    redirect_to masters_request_path(@request), notice: "견적이 제출되었습니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "견적 제출 실패: #{e.message}"
  end

  def start_construction
    authorize @request
    @request.start_construction!
    redirect_to masters_request_path(@request), notice: "공사를 시작합니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  def complete_construction
    authorize @request
    @request.construction_notes = params[:construction_notes] if params[:construction_notes].present?
    @request.construction_photos.attach(params[:construction_photos]) if params[:construction_photos].present?
    @request.complete_construction!
    NotificationService.notify_construction_completed(@request) rescue nil
    redirect_to masters_request_path(@request), notice: "공사가 완료되었습니다. 고객 확인을 기다립니다."
  rescue AASM::InvalidTransition => e
    redirect_to masters_request_path(@request), alert: "상태 변경 실패: #{e.message}"
  end

  private

  def set_request
    # show, apply, claim 액션은 공개 오더도 볼 수 있으므로 전체에서 찾음
    if action_name.in?(["show", "apply", "claim"])
      @request = Request.find(params[:id])
    else
      @request = current_user.assigned_requests.find(params[:id])
    end
  end
end
