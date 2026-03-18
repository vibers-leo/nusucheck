class Post < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  enum :category, {
    general: "general",
    tip: "tip",
    review: "review",
    question: "question"
  }, prefix: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :category, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }

  CATEGORY_LABELS = {
    "general"  => "일반",
    "tip"      => "누수 팁",
    "review"   => "해결 후기",
    "question" => "질문"
  }.freeze

  CATEGORY_COLORS = {
    "general"  => "bg-gray-100 text-gray-700",
    "tip"      => "bg-blue-100 text-blue-700",
    "review"   => "bg-green-100 text-green-700",
    "question" => "bg-amber-100 text-amber-700"
  }.freeze

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def category_color
    CATEGORY_COLORS[category] || "bg-gray-100 text-gray-700"
  end

  def increment_views!
    increment!(:views_count)
  end
end
