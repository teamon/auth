CONSUMER_KEY = "qp9hqefpuh34f"
CONSUMER_SECRET = "p8h243p9g3g"

class Auth < Application
  before :check_consumer_key
  
  def request_token
    token = Token.generate_request_token
    token.to_json
  end
  
  def access_token
    token = Token.first(:token => params[:token], :secret => params[:secret], :type => :request, :signed => true)
    raise Unauthorized unless token
    
    token.type = :access
    token.save
    
    token.to_json
  end
  
  def data
    token = Token.first(:token => params[:token], :secret => params[:secret], :type => :access, :signed => true)
    raise Unauthorized unless token
    token.user.to_json
  end
  
  protected
  
  def check_consumer_key
    raise Unauthorized if params[:consumer_key] != CONSUMER_KEY || params[:consumer_secret] != CONSUMER_SECRET
  end
end