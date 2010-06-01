require 'twitter'
class TwitterToken < ConsumerToken
  belongs_to :person
  
  after_create :update_username
  
  TWITTER_SETTINGS={:site=>"http://twitter.com"}
  def self.consumer
    @consumer||=OAuth::Consumer.new credentials[:key],credentials[:secret],TWITTER_SETTINGS
  end
  
  def client
    unless @client
      @twitter_oauth=Twitter::OAuth.new TwitterToken.consumer.key,TwitterToken.consumer.secret
      @twitter_oauth.authorize_from_access token,secret
      @client=Twitter::Base.new(@twitter_oauth)
    end
    
    @client
  end
  
  def update_username
    self.username = get_username
  end
  
  def get_username
    begin
      client.user_timeline.first.user.screen_name
    rescue
      ""
    end
  end
  
  def account_url
    "http://twitter.com/#{username}"
  end
  
end