require "rails_helper"

RSpec.describe "Payments::Webhooks", type: :request do
  let(:webhook_secret) { "portone_test_secret" }

  def portone_signature(body, secret)
    OpenSSL::HMAC.hexdigest("SHA256", secret, body)
  end

  # PortOneService 모킹용 헬퍼
  let(:port_one_service) { instance_double("PortOneService") }

  before do
    allow(PortOneService).to receive(:new).and_return(port_one_service)
  end

  describe "POST /payments/webhook" do
    let(:params) do
      {
        imp_uid: "imp_123456",
        merchant_uid: "MERCHANT-789",
        status: "paid"
      }
    end

    context "PORTONE_WEBHOOK_SECRET 설정 시" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]). with("PORTONE_WEBHOOK_SECRET").and_return(webhook_secret)
        allow(ENV).to receive(:fetch).and_call_original
      end

      context "유효한 서명" do
        it "200 응답" do
          body = params.to_query
          signature = portone_signature(body, webhook_secret)
          allow(port_one_service).to receive(:get_payment).and_return({ "status" => "paid" })

          post "/payments/webhook",
               params: params,
               headers: { "x-portone-signature" => signature }

          expect(response).to have_http_status(:ok)
        end
      end

      context "서명 헤더 없음" do
        it "401 Unauthorized 응답" do
          post "/payments/webhook",
               params: params

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Missing signature")
        end
      end

      context "잘못된 서명" do
        it "401 Unauthorized 응답" do
          post "/payments/webhook",
               params: params,
               headers: { "x-portone-signature" => "wrong_signature" }

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Invalid signature")
        end
      end
    end

    context "개발 환경에서 서명 없이 호출" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PORTONE_WEBHOOK_SECRET").and_return(nil)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it "서명 검증 스킵" do
        allow(port_one_service).to receive(:get_payment).and_return({ "status" => "paid" })

        post "/payments/webhook",
             params: params

        expect(response).to have_http_status(:ok)
      end
    end

    context "결제 취소 웹훅" do
      let(:customer) { create(:customer) }
      let(:master) { create(:master, :verified) }
      let(:leak_request) { create(:request, customer: customer) }
      let!(:escrow) do
        create(:escrow_transaction,
               request: leak_request,
               customer: customer,
               master: master,
               toss_order_id: "MERCHANT-CANCEL",
               status: "deposited",
               deposited_at: 1.hour.ago)
      end

      let(:cancel_params) do
        {
          imp_uid: "imp_cancel_123",
          merchant_uid: "MERCHANT-CANCEL",
          status: "cancelled"
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PORTONE_WEBHOOK_SECRET").and_return(nil)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
        allow(port_one_service).to receive(:get_payment).and_return({
          "status" => "cancelled",
          "cancel_amount" => 220_000,
          "cancel_reason" => "고객 요청"
        })
      end

      it "에스크로를 환불 처리" do
        post "/payments/webhook", params: cancel_params

        expect(response).to have_http_status(:ok)
        expect(escrow.reload).to be_refunded
      end

      it "감사 로그 기록" do
        expect {
          post "/payments/webhook", params: cancel_params
        }.to change(PaymentAuditLog, :count).by_at_least(1)
      end
    end

    context "imp_uid 누락" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("PORTONE_WEBHOOK_SECRET").and_return(nil)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
      end

      it "400 Bad Request 응답" do
        post "/payments/webhook",
             params: { merchant_uid: "MERCHANT-789", status: "paid" }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
