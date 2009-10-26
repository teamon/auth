class PAuth
  class Error < Exception; end
  
  cattr_accessor :consumer_key, :consumer_secret, :host, :port, :login_path,
                 :request_token_path, :access_token_path, :data_path
  
  attr_accessor :token, :secret, :type
  
  
  def initialize(token = nil, secret = nil)
    @token, @secret = token, secret
    @http = Net::HTTP.new(@@host, @@port)
  end
  
  def get_request_token!
    json = make_request(@@request_token_path, consumer_params)
    self.token = json[:token]
    self.secret = json[:secret]
    self.type = :request 
  end
  
  def get_access_token!
    json = make_request(@@access_token_path, params)
    self.token = json[:token]
    self.secret = json[:secret]
    self.type = :access
  end
  
  def get_data
    json = make_request(@@data_path, params)
  end
  
  def login_path
    Merb.logger.d! params
    "http://" + @@host + (@@port.blank? ? "" : ":#{@@port}" ) + make_path(@@login_path, params)
  end
  
  def self.configure
    yield self
  end
  
  protected
  
  def make_request(path, params)
    request = @http.get(make_path(path, params))
    
    if request.code.to_i == 200
      puts request.body
      JSON.parse(request.body).to_mash
    else
      raise Error.new(request.msg)
    end
    

  end
  
  def make_path(path, params = {})
    path + (path =~ /\?/ ? "&" : "?") + params.to_params
  end
  
  def params
    consumer_params.merge(:token => token, :secret => secret)
  end
  
  def consumer_params
    { :consumer_key => @@consumer_key, :consumer_secret => @@consumer_secret }
  end
end

PAuth.configure do |c|
  c.consumer_key = "qp9hqefpuh34f"
  c.consumer_secret = "p8h243p9g3g"
  c.host = "localhost"
  c.port = 4000
  c.request_token_path = "/auth/request_token"
  c.access_token_path = "/auth/access_token"
  c.data_path = "/auth/data"
  c.login_path = "/login"
end





class Auth < Application
  def perform_login
    auth = PAuth.new
    auth.get_request_token!
    
    Merb.logger.d auth
    
    session[:auth] = {
      :request_token => auth.token,
      :request_token_secret => auth.secret
    }
    
    redirect auth.login_path
  end
  
  def logout
    session.each_pair {|k,v| session[k] = nil }
    redirect "/"
  end
  
  def callback
    auth = PAuth.new(session[:auth][:request_token], session[:auth][:request_token_secret])
    auth.get_access_token!
    
    
    session[:auth] = {
      :access_token => auth.token,
      :access_token_secret => auth.secret
    }
    
    data = auth.get_data

    session[:logged_in] = true
    session[:user_id] = data[:id]
    redirect_back_or "/"
  end
  
  protected
  
  def redirect_back_or(uri)
    redirect session[:redirect_to].blank? ? uri : session[:redirect_to]
  end
end