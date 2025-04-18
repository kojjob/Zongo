class ContactMailer < ApplicationMailer
  def new_message(contact)
    @contact = contact

    mail(
      to: "kojcoder@gmail.com",
      subject: "New Contact Form Submission: #{contact.subject}"
    )
  end
end
