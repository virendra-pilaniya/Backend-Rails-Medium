class ApplicationController < ActionController::Base
    protect_from_forgery unless: -> { request.format.json? }

    def authenticate_user
        token = request.headers['Authorization']&.split&.last
        return unless token
    
        decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')
        user_id = decoded_token[0]['user_id']
        @current_user = User.find(user_id)
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        @current_user = nil
      end
    
      def current_user
        @current_user
      end
end
