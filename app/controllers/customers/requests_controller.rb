class Customers::RequestsController < ApplicationController
  include CustomerAccessible

  before_action :set_request, only: [
    :show, :cancel, :accept_estimate, :pay, :confirm_schedule,
    :deposit_trip_fee, :deposit_detection_fee, :deposit_escrow,
    :confirm_completion, :submit_complaint
  ]

  def index
    @q = current_user.requests.includes(:master, :estimates, :escrow_transactions,
                                        photos_attachments: :blob,
                                        videos_attachments: :blob).ransack(params[:q])
    @requests = @q.result.recent.page(params[:page])
  end

  def show
    authorize @request
  end

  def new
    @request = current_user.requests.build
  end

  def create
    @request = current_user.requests.build(request_params)

    if @request.save
      # 백그라운드에서 이메일 발송 (자동 재시도 3회)
      RequestMailerJob.perform_later("request_received", @request.id)
      # 관리자에게 새 체크 접수 알림
      RequestMailer.admin_new_request(@request).deliver_later rescue nil

      # AI 환영 메시지 발송
      SystemMessageService.send_welcome_message(@request)

      # 영상/사진이 첨부되었다면 확인 메시지
      if @request.photos.attached? || @request.videos.attached?
        SystemMessageService.send_video_received_message(@request)
      end

      # 영상 썸네일 생성
      VideoThumbnailJob.perform_later(@request.id) if @request.videos.attached?

      # 전문가 요청 모드(영상 업로드, 설명 없음)일 때 사전진단 유도 메시지
      if @request.videos.attached? && @request.description.blank?
        SystemMessageService.send_expert_request_prompt(@request)
      end

      # 전문가 매칭 진행 중 메시지
      SystemMessageService.send_matching_in_progress_message(@request)

      # 채팅방으로 리디렉션
      redirect_to request_messages_path(@request), notice: "누수 체크 접수가 완료되었습니다. AI 안내를 확인하세요!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    authorize @request
    if @request.may_cancel?
      @request.cancel!
      redirect_to customers_request_path(@request), notice: "신고가 취소되었습니다."
    else
      redirect_to customers_request_path(@request), alert: "현재 상태에서는 취소할 수 없습니다."
    end
  end

  def accept_estimate
    authorize @request
    estimate = @request.estimates.find(params[:estimate_id])
    ActiveRecord::Base.transaction do
      estimate.accept!
      @request.accept_estimate!

      # 견적 수락 후 자동으로 결제 요청 메시지 생성
      Message.create_payment_request!(
        request: @request,
        amount: estimate.total_amount,
        payment_method: "escrow",
        sender: @request.master
      )
    end

    NotificationService.notify_estimate_accepted(estimate) rescue nil
    redirect_to request_messages_path(@request), notice: "견적을 수락했습니다. 결제를 진행해주세요."
  rescue ActiveRecord::RecordNotFound
    redirect_to customers_request_path(@request), alert: "견적을 찾을 수 없습니다."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "견적 수락 실패: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "견적 수락에 실패했습니다. 잠시 후 다시 시도해주세요."
  rescue => e
    Rails.logger.error "견적 수락 중 알 수 없는 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to customers_request_path(@request), alert: "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  end

  # 결제 처리 (채팅방 위젯에서 호출)
  def pay
    authorize @request
    payment_method = params[:payment_method]  # "direct" or "escrow"
    estimate = @request.accepted_estimate

    unless estimate
      redirect_to request_messages_path(@request), alert: "수락된 견적이 없습니다."
      return
    end

    amount = estimate.total_amount

    if payment_method == "escrow"
      # 에스크로 결제 (Toss Payments 연동)
      escrow = EscrowService.new(@request).create_construction_escrow!(
        amount: amount,
        payment_method: "card"
      )

      if escrow.deposited?
        @request.deposit_escrow!

        # 결제 완료 메시지 생성
        Message.create_payment_complete!(
          request: @request,
          amount: amount,
          transaction_id: escrow.transaction_id || SecureRandom.hex(10)
        )

        redirect_to request_messages_path(@request), notice: "에스크로 결제가 완료되었습니다."
      else
        redirect_to request_messages_path(@request), alert: "결제에 실패했습니다."
      end
    else
      # 직접 결제 (계좌이체 안내)
      Message.create!(
        request: @request,
        sender: nil,
        message_type: :system,
        message_category: :system_notice,
        content: <<~DIRECT_PAYMENT.strip
          💳 직접 결제 안내

          전문가 계좌로 직접 입금해주세요:
          #{@request.master.master_profile&.bank_name} #{@request.master.master_profile&.account_number}
          예금주: #{@request.master.name}

          입금 후 채팅으로 알려주시면 확인 도와드릴게요!
        DIRECT_PAYMENT
      )

      redirect_to request_messages_path(@request), notice: "계좌 정보를 확인해주세요."
    end
  rescue => e
    Rails.logger.error "결제 중 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to request_messages_path(@request), alert: "결제 처리 중 오류가 발생했습니다."
  end

  # 일정 확정 (채팅방 위젯에서 호출)
  def confirm_schedule
    authorize @request
    message = Message.find(params[:message_id])

    unless message.schedule? && message.request_id == @request.id
      redirect_to request_messages_path(@request), alert: "일정 메시지를 찾을 수 없습니다."
      return
    end

    # 메타데이터 업데이트 (status: confirmed)
    message.update!(
      metadata: message.metadata.merge("status" => "confirmed")
    )

    # AASM 상태 전환
    @request.visit! if @request.may_visit?

    # 확정 완료 시스템 메시지
    Message.create!(
      request: @request,
      sender: nil,
      message_type: :system,
      message_category: :system_notice,
      content: <<~SCHEDULE_CONFIRMED.strip
        📅 일정이 확정되었어요!

        방문 일정: #{message.metadata['proposed_date']} #{message.metadata['time_slot']}

        💡 안내사항:
        • 방문 하루 전에 다시 한번 알림을 보내드려요
        • 일정 변경이 필요하면 채팅으로 말씀해주세요
        • 전문가가 약속 시간에 방문할 예정이에요

        준비 완료! 🚀
      SCHEDULE_CONFIRMED
    )

    redirect_to request_messages_path(@request), notice: "일정이 확정되었습니다."
  rescue => e
    Rails.logger.error "일정 확정 중 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to request_messages_path(@request), alert: "일정 확정 중 오류가 발생했습니다."
  end

  # ─── 1단계: 출장비 에스크로 ───────────────────────────────────
  def deposit_trip_fee
    authorize @request, :deposit_escrow?
    amount = params[:amount]&.to_d || @request.trip_fee.to_d
    unless amount > 0
      redirect_to customers_request_path(@request), alert: "출장비 금액이 없습니다."
      return
    end

    escrow = EscrowService.new(@request).create_trip_escrow!(
      amount: amount,
      payment_method: params[:payment_method] || "card"
    )
    redirect_to customers_request_path(@request), notice: "출장비 #{number_to_currency(escrow.amount, unit: "₩", precision: 0)} 입금 완료"
  rescue EscrowService::EscrowError => e
    Rails.logger.error "출장비 에스크로 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  rescue TossPaymentsService::PaymentError => e
    Rails.logger.error "토스 결제 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 카드 정보를 확인하고 다시 시도해주세요."
  rescue => e
    Rails.logger.error "출장비 결제 중 알 수 없는 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to customers_request_path(@request), alert: "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  end

  # ─── 2단계: 검사비 에스크로 ───────────────────────────────────
  def deposit_detection_fee
    authorize @request, :deposit_escrow?
    amount = params[:amount]&.to_d || @request.detection_fee.to_d
    unless amount > 0
      redirect_to customers_request_path(@request), alert: "검사비 금액이 없습니다."
      return
    end

    escrow = EscrowService.new(@request).create_detection_escrow!(
      amount: amount,
      payment_method: params[:payment_method] || "card"
    )
    redirect_to customers_request_path(@request), notice: "검사비 #{number_to_currency(escrow.amount, unit: "₩", precision: 0)} 입금 완료"
  rescue EscrowService::EscrowError => e
    Rails.logger.error "검사비 에스크로 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  rescue TossPaymentsService::PaymentError => e
    Rails.logger.error "토스 결제 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 카드 정보를 확인하고 다시 시도해주세요."
  rescue => e
    Rails.logger.error "검사비 결제 중 알 수 없는 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to customers_request_path(@request), alert: "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  end

  # ─── 3단계: 공사비 에스크로 (기존) ───────────────────────────
  def deposit_escrow
    authorize @request
    estimate = @request.accepted_estimate
    unless estimate
      redirect_to customers_request_path(@request), alert: "수락된 견적이 없습니다."
      return
    end

    escrow = EscrowService.new(@request).create_construction_escrow!(
      amount: estimate.total_amount,
      payment_method: params[:payment_method] || "card"
    )

    if escrow.deposited?
      @request.deposit_escrow!
      redirect_to customers_request_path(@request), notice: "공사비 에스크로 입금이 완료되었습니다."
    else
      redirect_to customers_request_path(@request), alert: "에스크로 입금에 실패했습니다."
    end
  rescue EscrowService::EscrowError => e
    Rails.logger.error "공사비 에스크로 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  rescue TossPaymentsService::PaymentError => e
    Rails.logger.error "토스 결제 오류: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to customers_request_path(@request), alert: "결제 처리 중 오류가 발생했습니다. 카드 정보를 확인하고 다시 시도해주세요."
  rescue => e
    Rails.logger.error "공사비 결제 중 알 수 없는 오류: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to customers_request_path(@request), alert: "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
  end

  def confirm_completion
    authorize @request
    if @request.may_confirm_completion?
      @request.confirm_completion!
      # 에스크로 지급 알림 (전문가에게)
      @request.escrow_transactions.where(status: :released).find_each do |txn|
        NotificationService.notify_payment_released(txn) rescue nil
      end
      redirect_to customers_request_path(@request), notice: "공사 완료가 확인되었습니다. 감사합니다!"
    else
      redirect_to customers_request_path(@request), alert: "현재 상태에서는 완료 확인을 할 수 없습니다."
    end
  end

  # ─── 고객 불만 제출 (완료 후 하자보수 요청) ──────────────────
  def submit_complaint
    authorize @request, :show?
    complaint_text = params[:complaint].presence
    unless complaint_text
      redirect_to customers_request_path(@request), alert: "불만 내용을 입력해주세요."
      return
    end

    @request.update!(
      customer_complaint: complaint_text,
      complaint_submitted_at: Time.current
    )
    redirect_to customers_request_path(@request), notice: "불만 사항이 접수되었습니다. 관리자가 빠르게 처리하겠습니다."
  end

  private

  def set_request
    @request = current_user.requests.find_by!(public_token: params[:id])
  end

  def request_params
    params.require(:request).permit(
      :symptom_type, :building_type, :address, :detailed_address,
      :floor_info, :description, :preferred_date, :request_source, photos: [], videos: []
    )
  end
end
