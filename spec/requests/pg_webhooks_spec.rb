require "rails_helper"

RSpec.describe "PgWebhooks", type: :request do
  let(:webhook_secret) { "test_webhook_secret_key" }

  def toss_signature(body, secret)
    Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", secret, body)
    )
  end

  describe "POST /pg/webhooks/toss" do
    let(:payload) do
      {
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          orderId: "ORDER-123",
          status: "DONE",
          paymentKey: "PK-abc"
        }
      }.to_json
    end

    context "TOSS_WEBHOOK_SECRET 미설정 시 (개발 환경)" do
      before { allow(ENV).to receive(:[]).and_call_original }
      before { allow(ENV).to receive(:[]).with("TOSS_WEBHOOK_SECRET").and_return(nil) }

      it "서명 검증 스킵하고 200 응답" do
        post "/pg/webhooks/toss",
             params: payload,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "TOSS_WEBHOOK_SECRET 설정 시" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TOSS_WEBHOOK_SECRET").and_return(webhook_secret)
        allow(ENV).to receive(:fetch).and_call_original
      end

      context "유효한 서명" do
        it "200 응답" do
          signature = toss_signature(payload, webhook_secret)

          post "/pg/webhooks/toss",
               params: payload,
               headers: {
                 "CONTENT_TYPE" => "application/json",
                 "X-TossPayments-Signature" => signature
               }

          expect(response).to have_http_status(:ok)
        end

        it "감사 로그 기록" do
          signature = toss_signature(payload, webhook_secret)

          expect {
            post "/pg/webhooks/toss",
                 params: payload,
                 headers: {
                   "CONTENT_TYPE" => "application/json",
                   "X-TossPayments-Signature" => signature
                 }
          }.to change(PaymentAuditLog, :count).by_at_least(1)
        end
      end

      context "서명 헤더 없음" do
        it "401 Unauthorized 응답" do
          post "/pg/webhooks/toss",
               params: payload,
               headers: { "CONTENT_TYPE" => "application/json" }

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Missing signature")
        end
      end

      context "잘못된 서명" do
        it "401 Unauthorized 응답" do
          post "/pg/webhooks/toss",
               params: payload,
               headers: {
                 "CONTENT_TYPE" => "application/json",
                 "X-TossPayments-Signature" => "invalid_signature_value"
               }

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)["error"]).to eq("Invalid signature")
        end
      end
    end

    context "잘못된 JSON payload" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TOSS_WEBHOOK_SECRET").and_return(nil)
      end

      it "400 Bad Request 응답" do
        post "/pg/webhooks/toss",
             params: "invalid json{{{",
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "PAYMENT_STATUS_CHANGED - CANCELED" do
      let(:customer) { create(:customer) }
      let(:master) { create(:master, :verified) }
      let(:leak_request) { create(:request, customer: customer) }
      let!(:escrow) do
        create(:escrow_transaction,
               request: leak_request,
               customer: customer,
               master: master,
               toss_order_id: "ORDER-CANCEL-123",
               status: "deposited",
               deposited_at: 1.hour.ago)
      end

      let(:cancel_payload) do
        {
          eventType: "PAYMENT_STATUS_CHANGED",
          data: {
            orderId: "ORDER-CANCEL-123",
            status: "CANCELED",
            paymentKey: "PK-cancel"
          }
        }.to_json
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TOSS_WEBHOOK_SECRET").and_return(nil)
      end

      it "에스크로를 환불 처리" do
        post "/pg/webhooks/toss",
             params: cancel_payload,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(escrow.reload).to be_refunded
      end
    end
  end
end
