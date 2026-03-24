require "rails_helper"

RSpec.describe RequestPolicy, type: :policy do
  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:master) { create(:master, :verified) }
  let(:other_master) { create(:master, :verified) }
  let(:admin) { create(:admin_user) }

  let(:leak_request) { create(:request, customer: customer) }
  let(:assigned_request) { create(:request, :assigned, customer: customer, master: master) }

  subject { described_class }

  describe "#show?" do
    it "관리자는 모든 요청 조회 가능" do
      expect(subject).to permit(admin, leak_request)
    end

    it "고객은 자신의 요청 조회 가능" do
      expect(subject).to permit(customer, leak_request)
    end

    it "다른 고객의 요청은 조회 불가" do
      expect(subject).not_to permit(other_customer, leak_request)
    end

    it "배정된 마스터는 해당 요청 조회 가능" do
      expect(subject).to permit(master, assigned_request)
    end

    it "배정되지 않은 마스터는 비공개 요청 조회 불가" do
      expect(subject).not_to permit(other_master, leak_request)
    end

    it "마스터는 공개(open) 요청 조회 가능" do
      leak_request.update_column(:status, "open")
      expect(subject).to permit(other_master, leak_request)
    end
  end

  describe "#create?" do
    it "고객만 요청 생성 가능" do
      expect(subject).to permit(customer, Request.new)
    end

    it "마스터는 요청 생성 불가" do
      expect(subject).not_to permit(master, Request.new)
    end

    it "관리자(Customer 타입)는 요청 생성 가능" do
      expect(subject).to permit(admin, Request.new)
    end
  end

  describe "#cancel?" do
    it "소유자가 취소 가능 상태이면 취소 가능" do
      expect(subject).to permit(customer, leak_request)
    end

    it "관리자가 취소 가능 상태이면 취소 가능" do
      expect(subject).to permit(admin, leak_request)
    end

    it "다른 고객은 취소 불가" do
      expect(subject).not_to permit(other_customer, leak_request)
    end
  end

  describe "#publish?" do
    it "관리자만 공개 가능" do
      expect(subject).to permit(admin, leak_request)
    end

    it "고객은 공개 불가" do
      expect(subject).not_to permit(customer, leak_request)
    end

    it "마스터는 공개 불가" do
      expect(subject).not_to permit(master, leak_request)
    end
  end

  describe "#claim?" do
    before { leak_request.update_column(:status, "open") }

    it "승인된 마스터만 오더 선택 가능" do
      expect(subject).to permit(master, leak_request)
    end

    it "미승인 마스터는 오더 선택 불가" do
      unverified_master = create(:master)
      expect(subject).not_to permit(unverified_master, leak_request)
    end

    it "고객은 오더 선택 불가" do
      expect(subject).not_to permit(customer, leak_request)
    end
  end

  describe "#assign_master?" do
    it "관리자만 마스터 배정 가능" do
      expect(subject).to permit(admin, leak_request)
    end

    it "고객은 마스터 배정 불가" do
      expect(subject).not_to permit(customer, leak_request)
    end
  end

  describe "마스터 전용 액션" do
    describe "#visit?" do
      it "배정된 마스터만 방문 가능" do
        expect(subject).to permit(master, assigned_request)
      end

      it "다른 마스터는 방문 불가" do
        expect(subject).not_to permit(other_master, assigned_request)
      end
    end
  end

  describe "고객 전용 액션" do
    describe "#accept_estimate?" do
      let(:estimate_submitted_request) do
        req = create(:request, customer: customer)
        req.update_column(:status, "estimate_submitted")
        req
      end

      it "소유 고객만 견적 수락 가능" do
        expect(subject).to permit(customer, estimate_submitted_request)
      end

      it "다른 고객은 견적 수락 불가" do
        expect(subject).not_to permit(other_customer, estimate_submitted_request)
      end
    end
  end

  describe "관리자 전용 액션" do
    describe "#finalize?" do
      let(:completed_request) do
        req = create(:request, customer: customer)
        req.update_column(:status, "construction_completed")
        req
      end

      it "관리자만 최종 종료 가능" do
        expect(subject).to permit(admin, completed_request)
      end

      it "고객은 최종 종료 불가" do
        expect(subject).not_to permit(customer, completed_request)
      end
    end
  end

  describe "Scope" do
    let!(:customer_request) { create(:request, customer: customer) }
    let!(:other_request) { create(:request, customer: other_customer) }
    let!(:master_request) { create(:request, :assigned, customer: other_customer, master: master) }

    it "관리자는 모든 요청 조회" do
      scope = Pundit.policy_scope(admin, Request)
      expect(scope).to include(customer_request, other_request, master_request)
    end

    it "고객은 자신의 요청만 조회" do
      scope = Pundit.policy_scope(customer, Request)
      expect(scope).to include(customer_request)
      expect(scope).not_to include(other_request)
    end

    it "마스터는 배정된 요청만 조회" do
      scope = Pundit.policy_scope(master, Request)
      expect(scope).to include(master_request)
      expect(scope).not_to include(customer_request)
    end
  end
end
