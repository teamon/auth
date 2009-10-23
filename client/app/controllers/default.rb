class Default < Application
  
  before :ensure_authenticated, :only => [:protected]
  
  def index
    render
  end
  
  def protected
    render
  end
  
  
  protected
  
  def ensure_authenticated
    unless session[:logged_in]
      session[:redirect_to] = request.uri
      raise Unauthorized
    end
  end
  
end