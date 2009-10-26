# :created_at time check



class PAuthServer
  cattr_accessor :consumer_key, :consumer_secret
  
  class << self
    
    def request_token
      token = Token.generate_request_token
      token.to_json
    end
    
    def access_token(token, secret)
      t = Token.first(:token => token, :secret => secret, 
                          :type => :request, :signed => true)
      raise Application::Unauthorized unless t

      t.type = :access
      t.regenerate_token_and_secret!
      t.save

      t.to_json
    end
    
    def data(token, secret)
      t = Token.first(:token => token, :secret => secret,
                          :type => :access, :signed => true)
      raise Application::Unauthorized unless t
      t.user.to_json
    end
    
  end
end

PAuthServer.consumer_key = "qp9hqefpuh34f"
PAuthServer.consumer_secret = "p8h243p9g3g"

class Auth < Application
  before :check_consumer_key
  
  def request_token
    PAuthServer.request_token
  end
  
  def access_token
    PAuthServer.access_token(params[:token], params[:secret])
  end
  
  def data
    PAuthServer.data(params[:token], params[:secret])
  end
  
  protected
  
  def check_consumer_key
    raise Unauthorized if params[:consumer_key] != PAuthServer.consumer_key || params[:consumer_secret] != PAuthServer.consumer_secret
  end
end