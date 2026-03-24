require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:notifications).dependent(:destroy) }
    it { should have_many(:user_coupons).dependent(:destroy) }
    it { should have_many(:coupons).through(:user_coupons) }
  end

  describe "validations" do
    context "등록된 사용자" do
      subject { build(:customer, account_status: :registered) }

      it { should validate_presence_of(:email) }
      it { should validate_uniqueness_of(:email) }
    end

    context "게스트 사용자" do
      let(:guest) { User.create_guest! }

      it "이메일 없이 생성 가능" do
        expect(guest).to be_persisted
        expect(guest).to be_guest
      end

      it "비밀번호 없이 생성 가능" do
        expect(guest.encrypted_password).to eq("")
      end
    end

    context "전화번호 형식" do
      let(:user) { build(:customer, account_status: :registered) }

      it "올바른 전화번호 형식 허용" do
        user.phone = "010-1234-5678"
        expect(user).to be_valid
      end

      it "잘못된 전화번호 형식 거부" do
        user.phone = "02-1234-5678"
        expect(user).not_to be_valid
      end

      it "빈 전화번호 허용" do
        user.phone = nil
        expect(user).to be_valid
      end
    end
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1) }
    it { should define_enum_for(:account_status).with_values(guest: 0, registered: 1, verified: 2) }
  end

  describe "역할 메서드" do
    describe "#customer?" do
      it "Customer 타입이면 true" do
        customer = create(:customer)
        expect(customer.customer?).to be true
      end

      it "Master 타입이면 false" do
        master = create(:master)
        expect(master.customer?).to be false
      end
    end

    describe "#master?" do
      it "Master 타입이면 true" do
        master = create(:master)
        expect(master.master?).to be true
      end

      it "Customer 타입이면 false" do
        customer = create(:customer)
        expect(customer.master?).to be false
      end
    end

    describe "#admin_user?" do
      it "admin 역할이면 true" do
        admin = create(:admin_user)
        expect(admin.admin_user?).to be true
      end

      it "일반 사용자이면 false" do
        customer = create(:customer)
        expect(customer.admin_user?).to be false
      end
    end
  end

  describe "#display_role" do
    it "관리자 역할 표시" do
      admin = create(:admin_user)
      expect(admin.display_role).to eq("관리자")
    end

    it "마스터 역할 표시" do
      master = create(:master)
      expect(master.display_role).to eq("마스터")
    end

    it "고객 역할 표시" do
      customer = create(:customer)
      expect(customer.display_role).to eq("고객")
    end
  end

  describe "게스트 계정" do
    describe ".create_guest!" do
      it "게스트 계정 생성" do
        guest = User.create_guest!
        expect(guest).to be_guest
        expect(guest.type).to eq("Customer")
        expect(guest.guest_token).to be_present
      end
    end

    describe "#upgrade_to_registered!" do
      let(:guest) { User.create_guest! }

      it "게스트를 등록 회원으로 전환" do
        guest.upgrade_to_registered!(email: "test@example.com", password: "password123", name: "테스트")
        expect(guest).to be_registered
        expect(guest.email).to eq("test@example.com")
        expect(guest.name).to eq("테스트")
      end
    end
  end

  describe "콜백" do
    it "기본 닉네임 설정 (이름 없을 때)" do
      user = create(:customer, name: nil)
      expect(user.name).to match(/\A물방울\d{4}\z/)
    end

    it "게스트 토큰 설정" do
      guest = User.create_guest!
      expect(guest.guest_token).to be_present
      expect(guest.guest_token.length).to be > 20
    end
  end
end
