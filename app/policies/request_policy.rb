class RequestPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || owner? || assigned_master? || (user.master? && record.open?)
  end

  def create?
    user.customer?
  end

  def cancel?
    (owner? || user.admin?) && record.may_cancel?
  end

  def publish?
    user.admin? && record.may_publish?
  end

  def assign_master?
    user.admin? && record.status.in?(%w[reported open])
  end

  def claim?
    user.master? &&
      user.master_profile&.verified? &&  # 승인된 전문가만 오더 선택 가능
      record.may_claim?
  end

  def accept_estimate?
    owner? && record.may_accept_estimate?
  end

  def deposit_escrow?
    owner? && record.may_deposit_escrow?
  end

  def confirm_completion?
    owner? && record.may_confirm_completion?
  end

  # Master actions
  def visit?
    assigned_master? && record.may_visit?
  end

  def arrive?
    assigned_master? && record.may_arrive?
  end

  def detection_complete?
    assigned_master? && record.may_detection_complete?
  end

  def detection_fail?
    assigned_master? && record.may_detection_fail?
  end

  def submit_estimate?
    assigned_master? && record.may_submit_estimate?
  end

  def start_construction?
    assigned_master? && record.may_start_construction?
  end

  def complete_construction?
    assigned_master? && record.may_complete_construction?
  end

  # Admin actions
  def close_no_charge?
    user.admin? && record.may_close_no_charge?
  end

  def finalize?
    user.admin? && record.may_finalize?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.customer?
        scope.where(customer_id: user.id)
      elsif user.master?
        scope.where(master_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def owner?
    record.customer_id == user.id
  end

  def assigned_master?
    user.master? && record.master_id == user.id
  end
end
