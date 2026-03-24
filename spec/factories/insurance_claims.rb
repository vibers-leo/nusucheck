FactoryBot.define do
  factory :insurance_claim do
    association :customer
    association :request, factory: :request
    applicant_name { "홍길동" }
    applicant_phone { "010-1234-5678" }
    applicant_email { "hong@example.com" }
    incident_address { "서울시 강남구 테헤란로 123" }
    incident_date { 3.days.ago.to_date }
    incident_description { "천장에서 물이 떨어지고 있습니다." }
    damage_type { "property_damage" }
    insurance_company { "삼성화재" }
    estimated_damage_amount { 500_000 }

    trait :with_master do
      association :prepared_by_master, factory: [:master, :verified]
    end

    trait :submitted do
      status { "submitted" }
      submitted_at { Time.current }
    end

    trait :under_review do
      status { "under_review" }
      submitted_at { 1.day.ago }
    end

    trait :approved do
      status { "approved" }
      submitted_at { 3.days.ago }
      reviewed_at { Time.current }
    end

    trait :pending_customer_review do
      status { "pending_customer_review" }
      association :prepared_by_master, factory: [:master, :verified]
    end
  end
end
