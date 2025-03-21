class EventComment < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :parent_comment, class_name: 'EventComment', optional: true
  has_many :replies, class_name: 'EventComment', foreign_key: 'parent_comment_id', dependent: :destroy
  
  # Validations
  validates :content, presence: true, length: { maximum: 1000 }
  
  # Scopes
  scope :root_comments, -> { where(parent_comment_id: nil) }
  scope :visible, -> { where(is_hidden: false) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Methods
  def root?
    parent_comment_id.nil?
  end
  
  def has_replies?
    replies.exists?
  end
  
  def visible_replies
    replies.visible
  end
  
  def hide!
    update(is_hidden: true)
  end
  
  def show!
    update(is_hidden: false)
  end
  
  def add_like!
    increment!(:likes_count)
  end
  
  def remove_like!
    decrement!(:likes_count) if likes_count > 0
  end
  
  def formatted_timestamp
    time_diff = Time.current - created_at
    
    if time_diff < 1.minute
      "Just now"
    elsif time_diff < 1.hour
      "#{(time_diff / 1.minute).to_i} minutes ago"
    elsif time_diff < 1.day
      "#{(time_diff / 1.hour).to_i} hours ago"
    elsif time_diff < 7.days
      "#{(time_diff / 1.day).to_i} days ago"
    else
      created_at.strftime("%b %d, %Y")
    end
  end
end
