class Article < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :ratings, dependent: :destroy

  # Plural array configuration allows multiple files per article
  has_many_attached :images

  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true, length: { minimum: 10 }

  # Content extension security validation loop
  validate :acceptable_images

  # Chronological timeline scopes
  scope :latest, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  private

  def acceptable_images
    return unless images.attached?

    images.each do |image|
      unless image.blob.content_type.in?(%w[image/jpeg image/png image/webp image/gif])
        errors.add(:images, "must all be JPEG, PNG, WEBP, or GIF files")
      end
    end
  end
end