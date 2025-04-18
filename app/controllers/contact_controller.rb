class ContactController < ApplicationController
  def index
    # Render the contact form page
  end

  def submit
    @contact = ContactSubmission.new(contact_params)

    # Set terms_accepted_at if terms is true
    @contact.terms_accepted_at = Time.current if @contact.terms?

    if @contact.save
      # Success response
      flash[:notice] = "Thank you for your message! We'll respond shortly."
      redirect_to contact_path
    else
      # Error response with validation errors
      flash.now[:alert] = "Please correct the following errors:"
      render :index
    end
  end

  private

  def contact_params
    params.permit(:name, :email, :phone, :subject, :read, :message, :terms)
  end
end
