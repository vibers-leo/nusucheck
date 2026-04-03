# frozen_string_literal: true

class Customers::PaymentsController < ApplicationController
  include CustomerAccessible

  # GET /customers/payments
  # 결제 내역 목록
  def index
    @payments = current_user.escrow_transactions
                           .includes(:request)
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(20)

    # 필터
    if params[:status].present?
      @payments = @payments.where(status: params[:status])
    end

    if params[:start_date].present? && params[:end_date].present?
      @payments = @payments.where(created_at: params[:start_date]..params[:end_date])
    end

    # 통계
    all_txns = current_user.escrow_transactions
    @total_amount   = all_txns.where(status: %w[deposited held released settled]).sum(:amount)
    @pending_amount = all_txns.where(status: 'pending').sum(:amount)
    @refunded_amount = all_txns.where(status: 'refunded').sum(:amount)
  end
end
