require "digest/md5"

class Token
  include DataMapper::Resource
  
  property :id,     Serial
  property :token,  String, :unique => true
  property :secret, String, :unique => true
  property :type,   Enum[:request, :access], :default => :request
  property :signed, Boolean
  property :created_at,   DateTime
  property :user_id, Integer, :nullable => true
  
  belongs_to :user
  
  def sign!(user)
    self.user = user
    self.signed = true
    self.save
  end
  
  def regenerate_token_and_secret!
    self.token = Digest::MD5.hexdigest(rand().to_s)
    self.secret = Digest::SHA1.hexdigest(rand().to_s)
  end
  
  class << self
  
    def generate_request_token
      token = Token.new
      token.regenerate_token_and_secret!
      token.save
      token
    end
  
  end
  
end