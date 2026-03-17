class Review < ApplicationRecord
  belongs_to :request
  belongs_to :customer, class_name: "Customer", inverse_of: :reviews
  belongs_to :master, class_name: "Master", inverse_of: :reviews

  alias_attribute :rating, :overall_rating

  validates :request_id, uniqueness: true
  validates :overall_rating, presence: true, numericality: { in: 1..5 }
  validates :punctuality_rating, :skill_rating, :kindness_rating,
            :cleanliness_rating, :price_rating,
            numericality: { in: 1..5 }, allow_nil: true

  before_validation :calculate_overall_rating

  scope :recent, -> { order(created_at: :desc) }

  def rating_details
    {
      punctuality: punctuality_rating,
      skill: skill_rating,
      kindness: kindness_rating,
      cleanliness: cleanliness_rating,
      price: price_rating
    }.compact
  end

  def rating_labels
    {
      punctuality: "시간 준수",
      skill: "기술력",
      kindness: "친절도",
      cleanliness: "뒷정리",
      price: "가격 만족"
    }
  end

  private

  def calculate_overall_rating
    ratings = [punctuality_rating, skill_rating, kindness_rating,
               cleanliness_rating, price_rating].compact
    self.overall_rating = ratings.any? ? (ratings.sum.to_f / ratings.size).round(2) : 0
  end
end
