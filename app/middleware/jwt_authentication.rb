# app/middleware/jwt_authentication.rb
class JwtAuthentication
    def initialize(app)
      @app = app
    end
  
    def call(env)
      token = extract_token_from_request(env)
  
      if token
        decoded_token = decode_token(token)
        if decoded_token
          user_id = decoded_token[0]['user_id']
          user = User.find_by(id: user_id)
  
          if user
            env['current_user'] = user
          end
        end
      end
  
      @app.call(env)
    end
  
    private
  
    def extract_token_from_request(env)
      auth_header = env['HTTP_AUTHORIZATION']
      if auth_header && auth_header.match(/^Bearer (.*)$/)
        return $1
      end
    end
  
    def decode_token(token)
      begin
        return JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')
      rescue JWT::DecodeError
        return nil
      end
    end
  end
  