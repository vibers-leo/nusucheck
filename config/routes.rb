Rails.application.routes.draw do
  # Health check endpoint for Fly.io
  get "up", to: "rails/health#show", as: :rails_health_check

  # === Devise (고객 전용 회원가입) ===
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
    # 카카오 로그인 (나중에 추가 예정)
    # omniauth_callbacks: "users/omniauth_callbacks"
  }

  # /expert 경로 (전문가 앱 - 단일 도메인)
  scope "/expert", as: "expert" do
    get "/", to: "expert/pages#index", as: :root
    devise_scope :user do
      get  "sign_up", to: "expert/registrations#new",    as: :sign_up
      post "sign_up", to: "expert/registrations#create",  as: :registration
    end
    get  "inquiry",  to: "expert/inquiries#new",    as: :inquiry
    post "inquiry",  to: "expert/inquiries#create",  as: :inquiry_submit

    # 전문가 대시보드 (로그인 후)
    get "dashboard", to: "expert/dashboard#index", as: :dashboard
    get "settlements", to: "expert/settlements#index", as: :settlements
  end

  # 토스페이먼츠 결제 콜백 (GET - 토스에서 리디렉트)
  scope "/customers" do
    get  "toss_payments/checkout", to: "customers/toss_payments#checkout",  as: :checkout_customers_toss_payments
    get  "toss_payments/success",  to: "customers/toss_payments#success",   as: :customers_toss_payments_success
    get  "toss_payments/fail",     to: "customers/toss_payments#fail",      as: :customers_toss_payments_fail
  end

  # 토스페이먼츠 웹훅 (POST - CSRF 제외)
  post "pg/webhooks/toss", to: "pg_webhooks#toss"

  # 포트원 결제 (신규)
  namespace :customers do
    scope :payments do
      get  "checkout",  to: "payments#checkout",  as: :payments_checkout
      get  "callback",  to: "payments#callback",  as: :payments_callback
    end
  end

  # 포트원 웹훅 (POST - CSRF 제외)
  post "payments/webhook", to: "payments/webhooks#portone"

  # Customer namespace
  namespace :customers do
    get "dashboard", to: "dashboard#index", as: :dashboard

    # 프로필 관리
    resource :profile, only: [:show, :edit, :update], controller: "profiles"

    # 설정 페이지
    get "settings", to: "settings#index", as: :settings
    namespace :settings do
      resource :notifications, only: [:show, :update], controller: "notifications"
    end

    # 결제 내역
    resources :payments, only: [:index]

    resources :requests, only: [:index, :show, :new, :create] do
      member do
        post :cancel
        post :accept_estimate
        post :pay                    # 채팅 위젯: 결제 처리
        patch :confirm_schedule      # 채팅 위젯: 일정 확정
        post :deposit_trip_fee       # 1단계: 출장비
        post :deposit_detection_fee  # 2단계: 검사비
        post :deposit_escrow         # 3단계: 공사비
        post :confirm_completion
        post :submit_complaint       # 하자보수 불만 접수
      end
      resources :reviews, only: [:new, :create]
      resources :insurance_claims, only: [:new, :create], controller: "insurance_claims"
    end
    resources :estimates, only: [:show]

    resources :insurance_claims, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        post :submit_claim
        post :customer_approve
        post :customer_request_changes
        get  :download_pdf
        patch :start_review          # 사용자가 수동 제출 후 심사 시작
        patch :auto_submit           # 보험사에 자동 이메일 발송
      end
    end

    # 전문가 목록/상세
    resources :masters, only: [:index, :show]
  end

  # Master namespace
  namespace :masters do
    resources :requests, only: [:index, :show] do
      collection do
        get :open_orders   # 공개 오더 목록
      end
      member do
        post :apply        # 전문가 신청 (당근마켓 스타일)
        post :claim        # 선착순 선택 (기존 호환성 유지)
        post :visit
        post :arrive
        post :detection_complete
        post :detection_fail
        post :submit_estimate
        post :start_construction
        post :complete_construction
      end
      resources :estimates, only: [:new, :create, :edit, :update]
      resources :insurance_claims, only: [:new, :create], controller: "insurance_claims"
    end
    resource :profile, only: [:show, :edit, :update], controller: "profiles" do
      post :upload_insurance, on: :member
    end

    # 보험 자동 조회 (CODEF API 간편인증)
    resource :insurance_verification, only: [:show], controller: "insurance_verifications" do
      post :request_auth, on: :member
      get  :waiting,      on: :member
      get  :poll,         on: :member
    end

    resources :insurance_claims, only: [:index, :show, :edit, :update] do
      member do
        post :send_to_customer
        get  :download_pdf
      end
    end

    # 구독 관리
    resources :subscriptions, only: [:index] do
      collection do
        patch :upgrade      # 플랜 업그레이드
        patch :downgrade    # 플랜 다운그레이드 (Free로)
      end
    end
  end

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :dashboard, only: [:index]
    resource :profile, only: [:show], controller: "profiles"
    resources :requests, only: [:index, :show] do
      member do
        post :publish        # 공개 오더 풀에 등록
        post :assign_master  # 관리자 직접 배정 (수동)
        post :close_no_charge
        post :finalize
        post :set_warranty        # 하자보수 보증기간 설정
        post :resolve_complaint   # 고객 불만 처리 완료
      end
    end
    resources :masters, only: [:index, :show] do
      member do
        post :verify
        post :reject
        post :approve_insurance
        post :reject_insurance
      end
    end
    resources :escrow_transactions, only: [:index, :show] do
      member do
        post :release_payment
        post :refund
      end
    end

    # 결제 감사 로그 (신규)
    resources :payment_audit_logs, only: [:index, :show]

    resources :insurance_claims, only: [:index, :show] do
      member do
        post :start_review
        post :approve
        post :reject
        post :complete
      end
    end

    # 피드백 및 설문조사 관리
    resources :feedbacks, only: [:index, :show] do
      member do
        post :mark_reviewed
        post :mark_resolved
      end
    end

    resources :surveys, only: [:index, :show]
  end

  # 전문가 공개 프로필 (비로그인 접근 가능)
  resources :masters, only: [:show]

  # PDF downloads
  resources :requests, only: [] do
    member do
      get :insurance_report_pdf
      get :estimate_pdf
      get :completion_report_pdf
    end

    # 채팅
    resources :messages, only: [:index, :create]
  end

  # API for standard estimate items
  namespace :api do
    resources :standard_estimate_items, only: [:index]
  end

  # Notifications
  resources :notifications, only: [:index] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # 채팅 목록 (로그인 필요)
  get "chats", to: "chats#index", as: :chats

  # AI 누수 빠른 점검 (비로그인 허용)
  resources :leak_inspections, only: [:new, :create, :show]

  # Health check (Fly.io)
  get "up", to: proc { [200, {}, ["OK"]] }

  # Email subscriptions (임시 랜딩페이지)
  resources :email_subscriptions, only: [:create]

  # 의견 보내기 (Feedback)
  resources :feedbacks, only: [:new, :create]

  # 설문조사 (Survey)
  resources :surveys, only: [:new, :create]

  # Static pages
  root "pages#coming_soon"
  get "about", to: "pages#about"
  get "pricing", to: "pages#pricing"
  get "how-it-works", to: "pages#how_it_works", as: :how_it_works
  get "reviews", to: "pages#reviews", as: :reviews
  get "faq", to: "pages#faq", as: :faq
  get "events", to: "pages#events", as: :events
  # 커뮤니티 (하단 탭 링크 유지 + CRUD)
  get "community", to: "posts#index", as: :community
  resources :posts, except: [:index]
  get "search", to: "search#index", as: :search
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
end
