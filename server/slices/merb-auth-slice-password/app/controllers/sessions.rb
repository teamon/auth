class MerbAuthSlicePassword::Sessions < MerbAuthSlicePassword::Application
  
  private   
  # @overwritable
  def redirect_after_login
    
    token = Token.first(:token => params[:token], :secret => params[:secret])
    if token
      token.sign!(session.user)
    else
      raise NotFound.new("Token not found")
    end

    session.abandon!
    redirect "http://localhost:3000/auth/callback"
  end


end