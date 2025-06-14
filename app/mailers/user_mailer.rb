# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer

  def activation_email(user)
    @user = user
    @activation_url = "https://api.marketincer.com/api/v1/activate/#{user.activation_token}"
    mail(to: @user.email, subject: 'Activate your account')
  end
end



