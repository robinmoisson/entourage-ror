module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:login, :code, :create]

      def login
        user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: user_params[:phone], sms_code: user_params[:sms_code])
        return render json: {message: 'unauthorized'}, status: :unauthorized unless user
        return render json: {message: 'deleted'}, status: :unauthorized if user.deleted

        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: user
      end

      def update
        avatar_file = user_params.delete(:avatar)
        if avatar_file
          UserServices::Avatar.new(user: @current_user).upload(file: avatar_file)
        end

        if @current_user.update_attributes(user_params)
          render json: @current_user, status: 200, serializer: ::V1::UserSerializer, scope: @current_user
        else
          head 400
        end
      end

      def create
        builder = UserServices::PublicUserBuilder.new(params: user_params)
        builder.create(send_sms: true) do |on|
          on.success do |user|
            render json: user, status: 201, serializer: ::V1::UserSerializer, scope: user
          end

          on.failure do |user|
            render json: {message: 'Could not sign up user', reasons: user.errors.full_messages}, status: :bad_request
          end
        end
      end

      def code
        if user_params[:phone].blank?
          return render json: {error: "Missing phone number"}, status:400
        end
        user_phone = Phone::PhoneBuilder.new(phone: user_params[:phone]).format
        user = User.where(phone: user_phone).first!

        if params[:code][:action] == "regenerate"
          UserServices::SMSSender.new(user: user).regenerate_sms!
          render json: user, status: 200, serializer: ::V1::UserSerializer, scope: user
        else
          render json: {error: "Unknown action"}, status:400
        end
      end

      def show
        user = params[:id] == "me" ? current_user : User.find(params[:id])
        render json: user, status: 200, serializer: ::V1::UserSerializer, scope: current_user
      end

      def destroy
        @current_user.update!(deleted: true)
        render json: @current_user, status: 200, serializer: ::V1::UserSerializer, scope: @current_user
      end

      private
      def user_params
        @user_params ||= params.require(:user).permit(:first_name, :last_name, :email, :sms_code, :phone, :avatar)
      end
    end
  end
end
