module Api
  module V1
    class AuthenticationController < ApplicationController
      skip_before_action :authenticate_token!, only: [:login, :register]

      def login
        user = User.find_by(email: login_params[:email])

        if user&.authenticate(login_params[:password])
          token = user.generate_token
          render json: {
            token: token,
            user: UserSerializer.new(user).serializable_hash[:data]
          }, status: :ok
        else
          render json: { message: 'Invalid credentials' }, status: :unauthorized
        end
      end

      def register
        user = User.new(register_params)

        if user.save
          token = user.generate_token
          render json: {
            token: token,
            user: UserSerializer.new(user).serializable_hash[:data]
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def register_params
        params.require(:user).permit(:email, :password, :name)
      end
    end
  end
end
