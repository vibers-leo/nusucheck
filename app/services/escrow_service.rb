class EscrowService
  class EscrowError < StandardError; end

  attr_reader :request

  def initialize(request)
    @request = request
  end

  # ─── 출장비 에스크로 (방문 전 선납) ───────────────────────────
  def create_trip_escrow!(amount:, payment_method: "card")
    create_staged_escrow!(escrow_type: "trip", amount: amount, payment_method: payment_method)
  end

  # ─── 검사비 에스크로 (현장 동의 후) ──────────────────────────
  def create_detection_escrow!(amount:, payment_method: "card")
    create_staged_escrow!(escrow_type: "detection", amount: amount, payment_method: payment_method)
  end

  # ─── 공사비 에스크로 (공사 시작 전 입금) ─────────────────────
  def create_construction_escrow!(amount:, payment_method: "card")
    create_staged_escrow!(escrow_type: "construction", amount: amount, payment_method: payment_method)
  end

  # ─── 공사비 대금 지급 (고객 완료 확인 시) ────────────────────
  def release_construction!
    escrow = request.construction_escrow || request.escrow_transactions.first
    raise EscrowError, "공사비 에스크로가 없습니다." unless escrow

    ActiveRecord::Base.transaction do
      escrow.release!
      simulate_pg_settlement(escrow)
      escrow.settle!
    end
  rescue AASM::InvalidTransition => e
    raise EscrowError, "대금 지급 실패: #{e.message}"
  end

  # ─── 특정 에스크로 타입 환불 ──────────────────────────────────
  def refund_by_type!(escrow_type)
    escrow = request.escrow_transactions.find_by(escrow_type: escrow_type)
    raise EscrowError, "#{escrow_type} 에스크로가 없습니다." unless escrow

    ActiveRecord::Base.transaction do
      simulate_pg_refund(escrow)
      escrow.refund!
    end
  rescue AASM::InvalidTransition => e
    raise EscrowError, "환불 실패: #{e.message}"
  end

  # ─── 전체 환불 (취소 시) ─────────────────────────────────────
  def refund_all!
    request.escrow_transactions.where(status: [:pending, :deposited, :held]).each do |escrow|
      simulate_pg_refund(escrow)
      escrow.refund! rescue nil
    end
  end

  # ─── 토스페이먼츠 결제 완료 후 DB 확정 ────────────────────────
  # TossPaymentsController#success에서 호출
  def finalize_payment!(escrow_type:, amount:, payment_key:, order_id:, payment_method: "card")
    ActiveRecord::Base.transaction do
      escrow = request.escrow_transactions.find_or_initialize_by(escrow_type: escrow_type)

      # 이미 deposited 상태라면 중복 처리 방지 (웹훅 재시도 대응)
      if escrow.persisted? && escrow.deposited?
        Rails.logger.warn "[EscrowService] 이미 처리된 결제: #{order_id}"
        return escrow
      end

      escrow.assign_attributes(
        customer:          request.customer,
        master:            request.master,
        amount:            amount,
        payment_method:    payment_method,
        pg_transaction_id: payment_key,
        toss_order_id:     order_id,
        toss_payment_key:  payment_key
      )
      escrow.save!
      escrow.deposit!

      # Request 상태 자동 전이 (공사비 에스크로인 경우)
      # reload로 캐시된 관계 초기화 후 가드 조건 재확인
      if escrow_type == "construction"
        request.reload
        request.deposit_escrow! if request.may_deposit_escrow?
      end

      escrow
    end
  rescue AASM::InvalidTransition => e
    raise EscrowError, "에스크로 상태 전이 실패: #{e.message}"
  end

  # ─── 하위 호환 메서드 (기존 코드 대응) ───────────────────────
  def create_and_deposit!(amount:, payment_method: "card")
    create_construction_escrow!(amount: amount, payment_method: payment_method)
  end

  def release!
    release_construction!
  end

  def refund!
    refund_all!
  end

  private

  def create_staged_escrow!(escrow_type:, amount:, payment_method:)
    ActiveRecord::Base.transaction do
      escrow = request.escrow_transactions.find_or_initialize_by(escrow_type: escrow_type)
      escrow.assign_attributes(
        customer: request.customer,
        master: request.master,
        amount: amount,
        payment_method: payment_method
      )
      escrow.save!

      pg_result = simulate_pg_payment(escrow)
      escrow.update!(pg_transaction_id: pg_result[:transaction_id])
      escrow.deposit!
      escrow
    end
  rescue AASM::InvalidTransition => e
    raise EscrowError, "에스크로 입금 실패: #{e.message}"
  end

  # MVP: PG사 결제 시뮬레이션
  def simulate_pg_payment(escrow)
    { success: true, transaction_id: "PG_#{SecureRandom.hex(10)}", amount: escrow.amount }
  end

  def simulate_pg_settlement(escrow)
    Rails.logger.info "[EscrowService] 정산: 마스터 #{escrow.master_id}에게 #{escrow.master_payout}원"
    true
  end

  def simulate_pg_refund(escrow)
    Rails.logger.info "[EscrowService] 환불: 고객 #{escrow.customer_id}에게 #{escrow.amount}원"
    true
  end
end
