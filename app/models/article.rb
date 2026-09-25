class Article < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :ratings, dependent: :destroy

  # Active Storage image attachment configuration
  has_one_attached :image

  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true, length: { minimum: 10 }

  # Content extension security alignment gate
  validate :acceptable_image

  # Chronological timeline scopes
  scope :latest, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.content_type.in?(%w[image/jpeg image/png image/webp image/gif])
      errors.add(:image, "must be a JPEG, PNG, WEBP, or GIF file")
    end
  end
end