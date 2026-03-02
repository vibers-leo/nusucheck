Rails.application.routes.draw do
  # Health check endpoint for Fly.io
  get "up", to: "rails/health#show", as: :rails_health_check

  # === Devise (고객 전용 회원가입) ===
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # === app.nusucheck.com → 고객 앱 진입점 ===
  # 루트만 지정, 나머지 라우트는 모든 도메인에서 공유
  constraints(SubdomainConstraint.new("app")) do
    root to: "customers/requests#index", as: :app_subdomain_root
  end

  # === 전문가 전용 라우트 ===
  # expert.nusucheck.com 서브도메인 또는 /expert 경로로 접근
  constraints(subdomain: "expert") do
    get "/", to: "expert/pages#index"
    devise_scope :user do
      get  "sign_up", to: "expert/registrations#new"
      post "sign_up", to: "expert/registrations#create"
    end
  end

  # /expert 경로 (서브도메인 없을 때도 접근 가능)
  scope "/expert", as: "expert" do
    get "/", to: "expert/pages#index", as: :root
    devise_scope :user do
      get  "sign_up", to: "expert/registrations#new",    as: :sign_up
      post "sign_up", to: "expert/registrations#create",  as: :registration
    end

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

    resources :requests, only: [:index, :show, :new, :create] do
      member do
        post :cancel
        post :accept_estimate
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
  end

  # Master namespace
  namespace :masters do
    resources :requests, only: [:index, :show] do
      collection do
        get :open_orders   # 공개 오더 목록
      end
      member do
        post :claim        # 선착순 선택
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
    resource :profile, only: [:show, :edit, :update], controller: "profiles"

    resources :insurance_claims, only: [:index, :show, :edit, :update] do
      member do
        post :send_to_customer
        get  :download_pdf
      end
    end
  end

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :dashboard, only: [:index]
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
  end

  # 전문가 검색 및 공개 프로필 (비로그인 접근 가능)
  resources :masters, only: [:index, :show]

  # PDF downloads
  resources :requests, only: [] do
    member do
      get :insurance_report_pdf
      get :estimate_pdf
      get :completion_report_pdf
    end
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

  # AI 누수 빠른 점검 (비로그인 허용)
  resources :leak_inspections, only: [:new, :create, :show]

  # Health check (Fly.io)
  get "up", to: proc { [200, {}, ["OK"]] }

  # Email subscriptions (임시 랜딩페이지)
  resources :email_subscriptions, only: [:create]

  # Static pages
  root "pages#coming_soon"
  get "home", to: "pages#home"
  get "about", to: "pages#about"
  get "pricing", to: "pages#pricing"
end
