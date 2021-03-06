module UserServices
  class PublicUserBuilder < UserBuilder

    def new_user(sms_code=nil)
      user = User.new(params)
      user.user_type = 'public'
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user
    end


    def update(user:)
      yield callback if block_given?

      return callback.on_failure.try(:call, user) if params.keys.include?("phone")

      avatar_file = params.delete(:avatar)
      if avatar_file
        UserServices::Avatar.new(user: user).upload(file: avatar_file)
      end

      should_send_email = params[:email] && user.email.nil?
      if user.update_attributes(params)
        MemberMailer.welcome(user).deliver_later if should_send_email
        callback.on_success.try(:call, user)
      else
        callback.on_failure.try(:call, user)
      end
    end
  end
end