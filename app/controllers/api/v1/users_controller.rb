module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:login, :code, :create]

      #curl -H "X-API-KEY:adc86c761fa8" -H "Content-Type: application/json" -X POST -d '{"user": {"phone": "+3312345567", "sms_code": "11111"}}' "http://localhost:3000/api/v1/login.json"
      def login
        user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: user_params[:phone], sms_code: user_params[:sms_code])

        unless PhoneValidator.new(phone: user_params[:phone]).valid?
          Rails.logger.info "SIGNIN_FAILED: invalid phone number format - params: #{params.inspect}"
          return render_error(code: "INVALID_PHONE_FORMAT", message: "invalid phone number format", status: 401)
        end

        unless user
          Rails.logger.info "SIGNIN_FAILED: wrong phone / sms_code combination - params: #{params.inspect}"
          return render_error(code: "UNAUTHORIZED", message: "wrong phone / sms_code", status: 401)
        end

        if user.deleted
          Rails.logger.info "SIGNIN_FAILED: deleted user - params: #{params.inspect}"
          return render_error(code: "DELETED", message: "user is deleted", status: 401)
        end

        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: user, full_partner: true }
      end

      #curl -X PATCH -d '{"user": { "sms_code":"123456"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/93.json?token=azerty"
      def update
        builder = UserServices::PublicUserBuilder.new(params: user_params)
        builder.update(user: @current_user) do |on|
          on.success do |user|
            mixpanel.sync_changes(user, {
              'first_name' => '$first_name',
              'email' => '$email'
            })

            render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: @current_user, full_partner: true }
          end

          on.failure do |user|
            render_error(code: "CANNOT_UPDATE_USER", message: user.errors.full_messages, status: 400)
          end
        end
      end

      #curl -X POST -d '{"user": { "phone":"+4068999999999"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/users.json?token=azerty"
      def create
        builder = UserServices::PublicUserBuilder.new(params: user_params)
        builder.create(send_sms: true) do |on|
          on.success do |user|
            mixpanel.distinct_id = user.id
            mixpanel.track("Created Account")
            render json: user, status: 201, serializer: ::V1::UserSerializer, scope: { user: user }
          end

          on.failure do |user|
            Rails.logger.info "SIGNUP_FAILED: invalid params - params: #{params.inspect}"
            render_error(code: "CANNOT_CREATE_USER", message: user.errors.full_messages, status: 400)
          end

          on.duplicate do
            Rails.logger.info "SIGNUP_FAILED: phone number already exists - params: #{params.inspect}"
            render_error(code: "PHONE_ALREADY_EXIST", message: "Phone #{user_params["phone"]} n'est pas disponible", status: 400)
          end

          on.invalid_phone_format do
            Rails.logger.info "SIGNUP_FAILED: invalid phone number format - params: #{params.inspect}"
            render_error(code: "INVALID_PHONE_FORMAT", message: "Phone devrait être au format +33... ou 06...", status: 400)
          end
        end
      end

      def code
        if user_params[:phone].blank?
          return render json: {error: "Missing phone number"}, status:400
        end
        user_phone = Phone::PhoneBuilder.new(phone: user_params[:phone]).format
        user = User.where(phone: user_phone).first!

        if params[:code][:action] == "regenerate" && !user.deleted
          UserServices::SMSSender.new(user: user).regenerate_sms!
          render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: user }
        else
          render json: {error: "Unknown action"}, status:400
        end
      end

      #curl -H "X-API-KEY:adc86c761fa8" -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/me.json?token=azerty"
      def show
        user = params[:id] == "me" ? current_user : User.find(params[:id])
        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: { user: current_user, full_partner: true }
      end

      def destroy
        UserServices::DeleteUserService.new(user: @current_user).delete
        render json: @current_user, status: 200, serializer: ::V1::UserSerializer, scope: { user: @current_user }
      end

      private
      def user_params
        @user_params ||= params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :avatar_key, :about)
      end
    end
  end
end
