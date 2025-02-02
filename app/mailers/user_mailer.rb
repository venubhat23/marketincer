# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def activation_email(user)
    @user = user
    # Update the activation URL to include the API namespace
    @activation_url = "https://marketincer-apis.onrender.com/api/v1/activate/#{user.activation_token}"
    
    mail(
      to: @user.email,
      subject: 'Activate your account'
    )
  end
end