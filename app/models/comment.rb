class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :parent, class_name: "Comment", optional: true

  has_many :replies, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy

  validates :content, presence: true

  scope :approved, -> { where(is_approved: true) }
  scope :pending_approval, -> { where(is_approved: false) }
  scope :top_level, -> { where(parent_id: nil) }

  def root_comment?
    parent_id.nil?
  end

  def has_replies?
    replies.any?
  end

  def approve!
    update(is_approved: true)
  end

  def reject!
    update(is_approved: false)
  end
end
