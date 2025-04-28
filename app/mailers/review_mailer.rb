class ReviewMailer < ApplicationMailer
  default from: 'notifications@superghana.com'
  
  def review_approved(review)
    @review = review
    @product = review.product
    @user = review.user
    
    mail(
      to: @user.email,
      subject: "Your review for #{@product.name} has been approved"
    )
  end
  
  def review_rejected(review)
    @review = review
    @product = review.product
    @user = review.user
    @admin_comment = review.admin_comment
    
    mail(
      to: @user.email,
      subject: "Your review for #{@product.name} requires changes"
    )
  end
end
