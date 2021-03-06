module UserServices
  class UserAuthenticator
    def self.authenticate_by_phone_and_sms(phone:, sms_code:)
      return nil if phone.blank? || sms_code.blank?

      user_phone = Phone::PhoneBuilder.new(phone: phone).format
      user = User.where(phone: user_phone).first
      return user if user.nil?

      valid_password = UserServices::PasswordService.new(user: user).check_password(sms_code)
      valid_password ? user : nil
    end

  end
end
