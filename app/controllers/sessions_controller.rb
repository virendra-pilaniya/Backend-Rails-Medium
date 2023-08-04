# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
    def create
      user = User.find_by(email: params[:email])
  
      if user&.authenticate(params[:password])
        # Generate JWT token and return it in the response
        token = JWT.encode({ user_id: user.id }, Rails.application.secrets.secret_key_base, 'HS256')
        render json: { token: token }, status: :ok
      else
        render json: { error: 'Invalid email or password.' }, status: :unauthorized
      end
    end
  end
  