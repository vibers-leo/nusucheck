require "rails_helper"

RSpec.describe Estimate, type: :model do
  describe "associations" do
    it { should belong_to(:request) }
    it { should belong_to(:master).class_name("Master") }
  end

  describe "validations" do
    it { should validate_numericality_of(:total_amount).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:request_id) }
    it { should validate_presence_of(:master_id) }
  end

  describe "스코프" do
    let!(:pending_estimate) { create(:estimate, status: "pending") }
    let!(:accepted_estimate) { create(:estimate, status: "accepted", accepted_at: Time.current) }

    it ".pending 는 대기 중인 견적만 반환" do
      expect(Estimate.pending).to include(pending_estimate)
      expect(Estimate.pending).not_to include(accepted_estimate)
    end

    it ".accepted 는 수락된 견적만 반환" do
      expect(Estimate.accepted).to include(accepted_estimate)
      expect(Estimate.accepted).not_to include(pending_estimate)
    end
  end

  describe "상태 메서드" do
    let(:estimate) { create(:estimate) }

    it "기본 상태는 pending" do
      expect(estimate).to be_pending
    end

    describe "#accept!" do
      it "상태를 accepted로 변경" do
        estimate.accept!
        expect(estimate).to be_accepted
        expect(estimate.accepted_at).to be_present
      end
    end

    describe "#reject!" do
      it "상태를 rejected로 변경" do
        estimate.reject!
        expect(estimate).to be_rejected
      end
    end

    describe "#expire!" do
      it "상태를 expired로 변경" do
        estimate.expire!
        expect(estimate).to be_expired
      end
    end
  end

  describe "#status_label" do
    it "한국어 라벨 반환" do
      estimate = build(:estimate, status: "pending")
      expect(estimate.status_label).to eq("검토 대기")

      estimate.status = "accepted"
      expect(estimate.status_label).to eq("수락됨")

      estimate.status = "rejected"
      expect(estimate.status_label).to eq("거절됨")

      estimate.status = "expired"
      expect(estimate.status_label).to eq("만료됨")
    end
  end

  describe "#parsed_line_items" do
    it "line_items를 HashWithIndifferentAccess 배열로 반환" do
      estimate = create(:estimate, line_items: [
        { category: "detection", name: "청음 탐지", amount: 150_000 }
      ])
      items = estimate.parsed_line_items
      expect(items.first[:category]).to eq("detection")
      expect(items.first["category"]).to eq("detection")
    end

    it "line_items가 nil이면 빈 배열 반환" do
      estimate = build(:estimate, line_items: nil)
      expect(estimate.parsed_line_items).to eq([])
    end
  end

  describe "금액 자동 계산 (before_save)" do
    it "카테고리별 소계와 VAT를 계산" do
      estimate = create(:estimate, line_items: [
        { category: "trip", name: "출장비", amount: 50_000 },
        { category: "detection", name: "탐지비", amount: 150_000 },
        { category: "construction", name: "공사비", amount: 300_000 },
        { category: "material", name: "자재비", amount: 100_000 }
      ])

      expect(estimate.detection_subtotal).to eq(150_000)
      expect(estimate.construction_subtotal).to eq(300_000)
      expect(estimate.material_subtotal).to eq(100_000)

      subtotal = 50_000 + 150_000 + 300_000 + 100_000
      expected_vat = (subtotal * 0.1).round(2)
      expect(estimate.vat).to eq(expected_vat)
      expect(estimate.total_amount).to eq(subtotal + expected_vat)
    end
  end
end
