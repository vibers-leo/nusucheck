class Admin::ProfilesController < ApplicationController
  include AdminAccessible

  def show
    @total_requests        = Request.count
    @total_masters         = Master.count
    @verified_masters      = MasterProfile.verified.count
    @total_customers       = Customer.count
    @total_revenue         = EscrowTransaction.where(status: ["released", "settled"]).sum(:platform_fee)
    @pending_requests      = Request.where(status: "reported").count
    @pending_insurance     = InsuranceClaim.where(status: ["draft", "pending_customer_review"]).count
  end
end
