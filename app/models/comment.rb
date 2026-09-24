# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :article

  # Minimum data rules
  validates :body, presence: true, length: { minimum: 10 }
  validates :commenter, presence: true

  # Native Rails State Engine Mapping
  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, default: :pending
end