class ApplicationController < ActionController::API
  before_action :authenticate_token!

  protected

  def authenticate_token!
    token = request.headers['Authorization']&.split(' ')&.last

    if token.blank?
      render json: { message: 'Missing token' }, status: :unauthorized
      return
    end

    begin
      @current_user = User.decode_token(token)
      render json: { message: 'Invalid token' }, status: :unauthorized if @current_user.nil?
    rescue JWT::DecodeError
      render json: { message: 'Invalid token' }, status: :unauthorized
    end
  end
end