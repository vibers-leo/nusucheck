# frozen_string_literal: true

puts "🌱 === 누수체크 시드 데이터 생성 시작 ==="
puts "⚠️  주의: 기존 데이터를 모두 삭제하고 새로 생성합니다"
puts ""

# 프로덕션 환경에서는 환경변수 ALLOW_SEED=true 설정 필요 (데모 환경용)
if Rails.env.production? && ENV["ALLOW_SEED"] != "true"
  puts "❌ 프로덕션 환경에서는 ALLOW_SEED=true 환경변수가 필요합니다!"
  puts "💡 데모 환경이라면: flyctl secrets set ALLOW_SEED=true"
  exit
end

# Geocoding 비활성화 (시드 데이터 생성 속도 향상 + 타임아웃 방지)
puts "🚫 Geocoding 임시 비활성화 (시드 데이터 생성 중)..."
Request.skip_callback(:validation, :after, :geocode)

# 기존 데이터 삭제
puts "🗑️  기존 데이터 삭제 중..."
Review.destroy_all
InsuranceClaim.destroy_all
EscrowTransaction.destroy_all
Estimate.destroy_all
Notification.destroy_all
Request.destroy_all
MasterProfile.destroy_all
User.destroy_all
StandardEstimateItem.destroy_all
puts "   ✓ 삭제 완료"
puts ""

# 1. 표준 견적 항목 (22개)
puts "📋 표준 견적 항목 생성 중..."

StandardEstimateItem.destroy_all

# 출장비 (1종)
StandardEstimateItem.create!([
  {
    category: "trip",
    name: "기본 출장비",
    description: "현장 방문 기본 출장비 (서울/수도권 기준)",
    unit: "건",
    min_price: 30_000,
    max_price: 80_000,
    default_price: 50_000,
    recommended_for: %w[wall_leak ceiling_leak floor_leak pipe_leak toilet_leak outdoor_leak],
    sort_order: 1
  }
])

# 탐지 (5종)
StandardEstimateItem.create!([
  {
    category: "detection",
    name: "청음 탐지",
    description: "청음기를 이용한 누수 지점 탐지",
    unit: "건",
    min_price: 100_000,
    max_price: 200_000,
    default_price: 150_000,
    recommended_for: %w[wall_leak ceiling_leak floor_leak pipe_leak],
    sort_order: 10
  },
  {
    category: "detection",
    name: "열화상 카메라 탐지",
    description: "적외선 열화상 카메라를 이용한 누수 범위 확인",
    unit: "건",
    min_price: 80_000,
    max_price: 150_000,
    default_price: 100_000,
    recommended_for: %w[wall_leak ceiling_leak floor_leak],
    sort_order: 11
  },
  {
    category: "detection",
    name: "질소 가압 테스트",
    description: "배관 내 질소 가압을 통한 누수 위치 확인",
    unit: "건",
    min_price: 150_000,
    max_price: 300_000,
    default_price: 200_000,
    recommended_for: %w[pipe_leak toilet_leak floor_leak],
    sort_order: 12
  },
  {
    category: "detection",
    name: "배관 내시경 검사",
    description: "소형 카메라를 이용한 배관 내부 상태 확인",
    unit: "건",
    min_price: 100_000,
    max_price: 250_000,
    default_price: 150_000,
    recommended_for: %w[pipe_leak toilet_leak],
    sort_order: 13
  },
  {
    category: "detection",
    name: "수분 측정기 검사",
    description: "벽면/바닥 수분 함유량 측정",
    unit: "건",
    min_price: 50_000,
    max_price: 100_000,
    default_price: 80_000,
    recommended_for: %w[wall_leak ceiling_leak outdoor_leak],
    sort_order: 14
  }
])

# 공사 (10종)
StandardEstimateItem.create!([
  {
    category: "construction",
    name: "배관 교체 (동파이프)",
    description: "기존 동파이프 배관 교체 공사",
    unit: "m",
    min_price: 30_000,
    max_price: 80_000,
    default_price: 50_000,
    recommended_for: %w[pipe_leak],
    sort_order: 20
  },
  {
    category: "construction",
    name: "배관 교체 (PVC)",
    description: "PVC 배관 교체 공사",
    unit: "m",
    min_price: 20_000,
    max_price: 50_000,
    default_price: 30_000,
    recommended_for: %w[pipe_leak toilet_leak],
    sort_order: 21
  },
  {
    category: "construction",
    name: "방수 공사 (바닥)",
    description: "화장실/바닥 방수 시공",
    unit: "㎡",
    min_price: 50_000,
    max_price: 120_000,
    default_price: 80_000,
    recommended_for: %w[floor_leak toilet_leak],
    sort_order: 22
  },
  {
    category: "construction",
    name: "방수 공사 (벽면)",
    description: "벽면 방수 시공",
    unit: "㎡",
    min_price: 40_000,
    max_price: 100_000,
    default_price: 70_000,
    recommended_for: %w[wall_leak outdoor_leak],
    sort_order: 23
  },
  {
    category: "construction",
    name: "방수 공사 (옥상/외벽)",
    description: "옥상 또는 외벽 방수 시공",
    unit: "㎡",
    min_price: 60_000,
    max_price: 150_000,
    default_price: 100_000,
    recommended_for: %w[ceiling_leak outdoor_leak],
    sort_order: 24
  },
  {
    category: "construction",
    name: "타일 철거 및 재시공",
    description: "기존 타일 철거 후 방수 및 타일 재시공",
    unit: "㎡",
    min_price: 80_000,
    max_price: 200_000,
    default_price: 130_000,
    recommended_for: %w[floor_leak toilet_leak],
    sort_order: 25
  },
  {
    category: "construction",
    name: "천장 보수",
    description: "누수로 인한 천장 석고보드 교체 및 보수",
    unit: "㎡",
    min_price: 30_000,
    max_price: 80_000,
    default_price: 50_000,
    recommended_for: %w[ceiling_leak],
    sort_order: 26
  },
  {
    category: "construction",
    name: "도배 보수",
    description: "누수로 인한 벽지 제거 및 재도배",
    unit: "㎡",
    min_price: 15_000,
    max_price: 40_000,
    default_price: 25_000,
    recommended_for: %w[wall_leak ceiling_leak],
    sort_order: 27
  },
  {
    category: "construction",
    name: "부분 철거",
    description: "누수 지점 접근을 위한 부분 철거 작업",
    unit: "건",
    min_price: 100_000,
    max_price: 300_000,
    default_price: 200_000,
    recommended_for: %w[wall_leak floor_leak pipe_leak],
    sort_order: 28
  },
  {
    category: "construction",
    name: "수전 교체",
    description: "노후 수전(수도꼭지) 교체",
    unit: "EA",
    min_price: 30_000,
    max_price: 100_000,
    default_price: 50_000,
    recommended_for: %w[pipe_leak toilet_leak],
    sort_order: 29
  }
])

# 자재 (6종)
StandardEstimateItem.create!([
  {
    category: "material",
    name: "방수 시트 (우레탄)",
    description: "우레탄 방수 시트",
    unit: "㎡",
    min_price: 10_000,
    max_price: 25_000,
    default_price: 15_000,
    recommended_for: %w[floor_leak wall_leak outdoor_leak],
    sort_order: 30
  },
  {
    category: "material",
    name: "방수 도료",
    description: "방수 코팅제/도료",
    unit: "L",
    min_price: 15_000,
    max_price: 40_000,
    default_price: 25_000,
    recommended_for: %w[wall_leak ceiling_leak outdoor_leak],
    sort_order: 31
  },
  {
    category: "material",
    name: "동파이프",
    description: "배관용 동파이프 자재",
    unit: "m",
    min_price: 8_000,
    max_price: 20_000,
    default_price: 12_000,
    recommended_for: %w[pipe_leak],
    sort_order: 32
  },
  {
    category: "material",
    name: "PVC 배관",
    description: "배관용 PVC 파이프",
    unit: "m",
    min_price: 3_000,
    max_price: 10_000,
    default_price: 5_000,
    recommended_for: %w[pipe_leak toilet_leak],
    sort_order: 33
  },
  {
    category: "material",
    name: "실리콘/코킹제",
    description: "방수용 실리콘 및 코킹제",
    unit: "EA",
    min_price: 5_000,
    max_price: 15_000,
    default_price: 8_000,
    recommended_for: %w[wall_leak toilet_leak outdoor_leak],
    sort_order: 34
  },
  {
    category: "material",
    name: "타일 자재",
    description: "교체용 타일 및 접착제",
    unit: "㎡",
    min_price: 20_000,
    max_price: 60_000,
    default_price: 35_000,
    recommended_for: %w[floor_leak toilet_leak],
    sort_order: 35
  }
])

puts "  -> 표준 견적 항목 #{StandardEstimateItem.count}개 생성 완료"

# 2. 데모 관리자 계정
puts "데모 계정 생성 중..."

admin = User.find_or_create_by!(email: "admin@nusucheck.kr") do |u|
  u.name = "관리자"
  u.password = "password123"
  u.phone = "010-0000-0000"
  u.role = :admin
  u.type = "Customer" # Admin은 STI 타입이 필요, role로 구분
end
puts "  -> 관리자: admin@nusucheck.kr / password123"

# 실제 관리자 계정 (designd)
designd_admin = User.find_or_create_by!(email: "designd@designd.co.kr") do |u|
  u.name = "DesignD"
  u.password = "designd2024!"
  u.phone = "010-0000-0001"
  u.role = :admin
  u.type = "Customer"
end
puts "  -> 실제 관리자: designd@designd.co.kr (admin 권한)"

# 3. 데모 고객 계정
customer = Customer.find_or_create_by!(email: "customer@example.com") do |u|
  u.name = "김철수"
  u.password = "password123"
  u.phone = "010-1234-5678"
  u.address = "서울시 강남구 테헤란로 123"
end
puts "  -> 고객: customer@example.com / password123"

customer2 = Customer.find_or_create_by!(email: "customer2@example.com") do |u|
  u.name = "이영희"
  u.password = "password123"
  u.phone = "010-9876-5432"
  u.address = "서울시 서초구 서초대로 456"
end

# 4. 데모 마스터 계정
master = Master.find_or_create_by!(email: "master@example.com") do |u|
  u.name = "박누수"
  u.password = "password123"
  u.phone = "010-5555-1234"
  u.address = "서울시 송파구 올림픽로 789"
end

master.master_profile.update!(
  license_number: "누수탐지-2024-001",
  license_type: "누수탐지전문기사",
  equipment: ["청음기", "열화상카메라", "질소가압기", "배관내시경"],
  service_areas: ["서울 강남구", "서울 서초구", "서울 송파구", "서울 강동구"],
  experience_years: 8,
  bank_name: "국민은행",
  account_number: "123-456-789012",
  account_holder: "박누수",
  verified: true,
  verified_at: Time.current,
  bio: "8년 경력의 누수 탐지 전문가입니다. 정확한 탐지와 합리적인 가격으로 최선을 다하겠습니다."
)
puts "  -> 마스터: master@example.com / password123 (인증됨)"

master2 = Master.find_or_create_by!(email: "master2@example.com") do |u|
  u.name = "최배관"
  u.password = "password123"
  u.phone = "010-6666-4321"
  u.address = "서울시 마포구 월드컵로 321"
end

master2.master_profile.update!(
  license_number: "누수탐지-2024-002",
  license_type: "배관설비기사",
  equipment: ["청음기", "수분측정기"],
  service_areas: ["서울 마포구", "서울 용산구", "서울 서대문구"],
  experience_years: 5,
  bank_name: "신한은행",
  account_number: "987-654-321098",
  account_holder: "최배관",
  verified: true,
  verified_at: Time.current,
  bio: "배관 전문가 최배관입니다. 배관 교체 및 수리 전문으로 합니다."
)

master3 = Master.find_or_create_by!(email: "master3@example.com") do |u|
  u.name = "정미인증"
  u.password = "password123"
  u.phone = "010-7777-9999"
  u.address = "서울시 영등포구 여의대로 100"
end
# master3는 미인증 상태로 유지

# 5. 데모 누수 신고
puts "데모 신고 데이터 생성 중..."

# 진행 중 신고 (마스터 배정됨)
request1 = Request.find_or_create_by!(customer: customer, address: "서울시 강남구 테헤란로 123, 아파트 301호") do |r|
  r.symptom_type = :wall_leak
  r.building_type = :apartment
  r.detailed_address = "아파트 301호"
  r.floor_info = "3층"
  r.description = "거실 벽면에서 물이 스며들고 있습니다. 벽지가 젖어서 곰팡이가 피기 시작했습니다."
  r.preferred_date = 3.days.from_now
end

if request1.reported?
  request1.assign!(master: master)
end

# 탐지 완료 신고
request2 = Request.find_or_create_by!(customer: customer, address: "서울시 강남구 테헤란로 123, 아파트 301호 화장실") do |r|
  r.symptom_type = :toilet_leak
  r.building_type = :apartment
  r.detailed_address = "아파트 301호 안방 화장실"
  r.floor_info = "3층"
  r.description = "안방 화장실 바닥에서 아래층으로 물이 새고 있다는 연락을 받았습니다."
  r.preferred_date = 1.day.ago
end

if request2.reported?
  request2.assign!(master: master)
  request2.visit!
  request2.arrive!
  request2.update!(detection_result: :leak_confirmed, detection_notes: "화장실 바닥 방수층 파손 확인. 배관 연결부 누수 동시 발견.")
  request2.detection_complete!
end

# 완료된 신고 (리뷰 포함)
request3 = Request.find_or_create_by!(customer: customer2, address: "서울시 서초구 서초대로 456, 빌라 201호") do |r|
  r.symptom_type = :ceiling_leak
  r.building_type = :villa
  r.detailed_address = "빌라 201호"
  r.floor_info = "2층"
  r.description = "윗집에서 물이 새는지 천장에서 계속 물방울이 떨어집니다."
end

if request3.reported?
  request3.assign!(master: master2)
  request3.visit!
  request3.arrive!
  request3.update!(detection_result: :leak_confirmed, detection_notes: "윗층 화장실 배관 이음새 부분 누수 확인")
  request3.detection_complete!

  # 견적 생성
  estimate3 = request3.estimates.create!(
    master: master2,
    line_items: [
      { category: "trip", name: "기본 출장비", unit: "건", quantity: 1, unit_price: 50_000, amount: 50_000 },
      { category: "detection", name: "청음 탐지", unit: "건", quantity: 1, unit_price: 150_000, amount: 150_000 },
      { category: "construction", name: "배관 교체 (PVC)", unit: "m", quantity: 3, unit_price: 30_000, amount: 90_000 },
      { category: "construction", name: "천장 보수", unit: "㎡", quantity: 2, unit_price: 50_000, amount: 100_000 },
      { category: "material", name: "PVC 배관", unit: "m", quantity: 3, unit_price: 5_000, amount: 15_000 }
    ],
    notes: "배관 이음새 교체 및 천장 석고보드 보수 포함",
    valid_until: 7.days.from_now
  )

  request3.submit_estimate!
  estimate3.accept!
  request3.accept_estimate!

  # 에스크로 (EscrowService 사용)
  escrow_service = EscrowService.new(request3)
  escrow = escrow_service.create_construction_escrow!(
    amount: estimate3.total_amount,
    payment_method: "card"
  )
  escrow.update!(pg_transaction_id: "PG_DEMO_#{SecureRandom.hex(8)}")
  request3.deposit_escrow!

  request3.start_construction!
  request3.complete_construction!
  request3.confirm_completion!

  # 리뷰
  Review.find_or_create_by!(request: request3) do |r|
    r.customer = customer2
    r.master = master2
    r.punctuality_rating = 5
    r.skill_rating = 4
    r.kindness_rating = 5
    r.cleanliness_rating = 4
    r.price_rating = 4
    r.comment = "빠르고 정확하게 처리해주셨습니다. 설명도 친절하게 해주시고, 가격도 합리적이었습니다. 감사합니다!"
  end
end

puts "   ✓ 데모 신고 #{Request.count}개 생성 완료"

# 6. 추가 데모 데이터 (공개 오더, 더 많은 리뷰 등)
puts "🎯 추가 데모 데이터 생성 중..."

# 고객 2명 더 추가
customer3 = Customer.create!(email: "customer3@test.com", name: "정민수", password: "password123", phone: "010-3333-4444", address: "서울시 송파구 올림픽로 333")
customer4 = Customer.create!(email: "customer4@test.com", name: "한소영", password: "password123", phone: "010-4444-5555", address: "서울시 강동구 천호대로 444")

# 공개 오더 3건 (선착순 대기)
open_order1 = Request.create!(
  customer: customer3,
  symptom_type: :pipe_leak,
  building_type: :apartment,
  address: "서울시 송파구 잠실동 123-45",
  detailed_address: "아파트 1502호",
  floor_info: "15층",
  description: "주방 싱크대 아래에서 물이 계속 새고 있어요. 급해요!",
  preferred_date: 2.days.from_now,
  status: :reported
)
open_order1.publish!

open_order2 = Request.create!(
  customer: customer4,
  symptom_type: :ceiling_leak,
  building_type: :villa,
  address: "서울시 마포구 상암동 789-12",
  detailed_address: "빌라 302호",
  floor_info: "3층",
  description: "거실 천장에서 물이 떨어져요. 윗집 문제인 것 같습니다.",
  preferred_date: 1.day.from_now,
  status: :reported
)
open_order2.publish!

open_order3 = Request.create!(
  customer: customer,
  symptom_type: :wall_leak,
  building_type: :apartment,
  address: "서울시 서초구 방배동 456-78",
  detailed_address: "오피스텔 805호",
  floor_info: "8층",
  description: "화장실 벽면에 물이 차오르고 있습니다.",
  preferred_date: 3.days.from_now,
  status: :reported
)
open_order3.publish!

puts "   ✓ 공개 오더 3건 생성"

# 더 많은 완료 + 리뷰 추가
2.times do |i|
  completed_req = Request.create!(
    customer: [customer3, customer4][i],
    symptom_type: [:floor_leak, :outdoor_leak][i],
    building_type: :apartment,
    address: ["서울시 강남구 논현동 111-22", "서울시 용산구 이촌동 333-44"][i],
    detailed_address: "#{rand(5..20)}층 #{rand(501..2005)}호",
    floor_info: "#{rand(5..20)}층",
    description: ["바닥 난방에서 물이 새는 것 같아요", "발코니 외벽에서 누수가 있습니다"][i],
    preferred_date: 15.days.ago
  )

  completed_req.assign!(master: [master, master2][i])
  completed_req.visit!
  completed_req.arrive!
  completed_req.update!(detection_result: :leak_confirmed, detection_notes: "정밀 탐지 완료")
  completed_req.detection_complete!

  est = completed_req.estimates.create!(
    master: [master, master2][i],
    line_items: [
      { category: "trip", name: "기본 출장비", unit: "건", quantity: 1, unit_price: 50_000, amount: 50_000 },
      { category: "detection", name: "열화상 카메라 탐지", unit: "건", quantity: 1, unit_price: 100_000, amount: 100_000 },
      { category: "construction", name: "방수 공사", unit: "㎡", quantity: 10, unit_price: 80_000, amount: 800_000 }
    ],
    notes: "방수 공사 필요",
    valid_until: 7.days.from_now
  )

  completed_req.submit_estimate!
  est.accept!
  completed_req.accept_estimate!

  # 에스크로 (EscrowService 사용)
  escrow_svc = EscrowService.new(completed_req)
  esc = escrow_svc.create_construction_escrow!(
    amount: est.total_amount,
    payment_method: "card"
  )
  esc.update!(pg_transaction_id: "PG_SEED_#{SecureRandom.hex(8)}")
  completed_req.deposit_escrow!
  completed_req.start_construction!
  completed_req.complete_construction!
  completed_req.confirm_completion!

  Review.create!(
    request: completed_req,
    customer: completed_req.customer,
    master: completed_req.master,
    punctuality_rating: [4, 5][i],
    skill_rating: [5, 4][i],
    kindness_rating: 5,
    cleanliness_rating: [4, 5][i],
    price_rating: 4,
    comment: ["정말 만족스러웠어요! 추천합니다.", "꼼꼼하고 친절하셨습니다."][i]
  )
end

puts "   ✓ 완료 + 리뷰 2건 추가"

puts ""
puts "🎉 === 누수체크 시드 데이터 생성 완료 ==="
puts ""
puts "🔑 테스트 계정 정보:"
puts "   👑 관리자: admin@nusucheck.kr / password123"
puts "   👤 고객1:  customer@example.com / password123"
puts "   👤 고객2:  customer2@example.com / password123"
puts "   👤 고객3:  customer3@test.com / password123"
puts "   👤 고객4:  customer4@test.com / password123"
puts "   👨‍🔧 전문가1 (박누수): master@example.com / password123 ✓인증됨"
puts "   👨‍🔧 전문가2 (최배관): master2@example.com / password123 ✓인증됨"
puts "   👨‍🔧 전문가3 (정미인증): master3@example.com / password123 ⚠️미인증"
puts ""
puts "📊 생성된 데이터 요약:"
puts "   - 표준 견적 항목: #{StandardEstimateItem.count}개"
puts "   - 전체 사용자: #{User.count}명 (고객 #{Customer.count}명, 전문가 #{Master.count}명)"
puts "   - 누수 체크: #{Request.count}건"
puts "     • 완료 (리뷰 포함): #{Request.where(status: 'closed').count}건"
puts "     • 공개 오더 (선착순): #{Request.where(status: 'open').count}건"
puts "     • 진행 중: #{Request.where.not(status: ['open', 'closed', 'cancelled']).count}건"
puts "   - 견적서: #{Estimate.count}건"
puts "   - 에스크로: #{EscrowTransaction.count}건"
puts "   - 리뷰: #{Review.count}건"
puts ""
puts "🌐 배포 URL: https://nusucheck.fly.dev"
puts "✨ 이제 로그인해서 모든 기능을 체험하실 수 있습니다!"
puts ""
