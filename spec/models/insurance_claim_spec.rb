require "rails_helper"

RSpec.describe InsuranceClaim, type: :model do
  describe "associations" do
    it { should belong_to(:customer).class_name("Customer") }
    it { should belong_to(:request).optional }
    it { should belong_to(:prepared_by_master).class_name("Master").optional }
  end

  describe "validations" do
    it { should validate_presence_of(:applicant_name) }
    it { should validate_presence_of(:applicant_phone) }
    it { should validate_presence_of(:incident_address) }
    it { should validate_presence_of(:incident_date) }
    it { should validate_presence_of(:incident_description) }

    describe "claim_number 고유성" do
      let!(:existing_claim) { create(:insurance_claim) }

      it "중복된 claim_number 거부" do
        new_claim = build(:insurance_claim, claim_number: existing_claim.claim_number)
        expect(new_claim).not_to be_valid
        expect(new_claim.errors[:claim_number]).to be_present
      end
    end
  end

  describe "claim_number 자동 생성" do
    it "생성 시 claim_number가 자동 부여" do
      claim = create(:insurance_claim)
      expect(claim.claim_number).to match(/\AINS-\d{6}-[A-F0-9]{8}\z/)
    end

    it "각 청구서마다 고유한 claim_number" do
      customer = create(:customer)
      claim1 = create(:insurance_claim, customer: customer)
      claim2 = create(:insurance_claim, customer: customer)
      expect(claim1.claim_number).not_to eq(claim2.claim_number)
    end
  end

  describe "AASM 상태 전이" do
    let(:claim) { create(:insurance_claim) }

    it "초기 상태는 draft" do
      expect(claim).to be_draft
    end

    describe "고객 직접 제출 플로우" do
      it "draft → submitted" do
        claim.submit_claim!
        expect(claim).to be_submitted
        expect(claim.submitted_at).to be_present
      end

      it "submitted → under_review" do
        claim.submit_claim!
        claim.start_review!
        expect(claim).to be_under_review
      end

      it "under_review → approved" do
        claim.submit_claim!
        claim.start_review!
        claim.approve!
        expect(claim).to be_approved
        expect(claim.reviewed_at).to be_present
      end

      it "under_review → rejected" do
        claim.submit_claim!
        claim.start_review!
        claim.reject!
        expect(claim).to be_rejected
        expect(claim.reviewed_at).to be_present
      end

      it "approved → completed" do
        claim.submit_claim!
        claim.start_review!
        claim.approve!
        claim.complete!
        expect(claim).to be_completed
        expect(claim.completed_at).to be_present
      end
    end

    describe "마스터 대행 작성 플로우" do
      let(:claim) { create(:insurance_claim, :with_master) }

      it "draft → pending_customer_review" do
        claim.send_to_customer!
        expect(claim).to be_pending_customer_review
      end

      it "pending_customer_review → submitted (고객 승인)" do
        claim.send_to_customer!
        claim.customer_approve!
        expect(claim).to be_submitted
        expect(claim.customer_reviewed).to be true
        expect(claim.customer_reviewed_at).to be_present
        expect(claim.submitted_at).to be_present
      end

      it "pending_customer_review → draft (고객 수정 요청)" do
        claim.send_to_customer!
        claim.customer_request_changes!
        expect(claim).to be_draft
      end
    end

    describe "잘못된 전이" do
      it "draft에서 바로 approved 불가" do
        expect { claim.approve! }.to raise_error(AASM::InvalidTransition)
      end

      it "submitted에서 바로 completed 불가" do
        claim.submit_claim!
        expect { claim.complete! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe "#status_label" do
    it "각 상태에 대한 한국어 라벨 반환" do
      claim = build(:insurance_claim, status: "draft")
      expect(claim.status_label).to eq("작성 중")

      claim.status = "pending_customer_review"
      expect(claim.status_label).to eq("고객 확인 대기")

      claim.status = "submitted"
      expect(claim.status_label).to eq("신청 완료")

      claim.status = "under_review"
      expect(claim.status_label).to eq("심사 중")

      claim.status = "approved"
      expect(claim.status_label).to eq("승인")

      claim.status = "rejected"
      expect(claim.status_label).to eq("반려")

      claim.status = "completed"
      expect(claim.status_label).to eq("완료")
    end
  end

  describe "#prepared_by_master?" do
    it "마스터가 작성한 청구서이면 true" do
      claim = create(:insurance_claim, :with_master)
      expect(claim.prepared_by_master?).to be true
    end

    it "마스터 없이 작성된 청구서이면 false" do
      claim = create(:insurance_claim)
      expect(claim.prepared_by_master?).to be false
    end
  end

  describe "#pending_customer_approval?" do
    it "마스터 작성 + 고객 검토 대기 상태이면 true" do
      claim = create(:insurance_claim, :pending_customer_review)
      expect(claim.pending_customer_approval?).to be true
    end
  end

  describe "#damage_type_label" do
    it "피해 유형 한국어 라벨 반환" do
      claim = build(:insurance_claim, damage_type: "property_damage")
      expect(claim.damage_type_label).to eq("재산 피해")

      claim.damage_type = "personal_injury"
      expect(claim.damage_type_label).to eq("인적 피해")

      claim.damage_type = "both"
      expect(claim.damage_type_label).to eq("재산 + 인적 피해")
    end
  end
end
