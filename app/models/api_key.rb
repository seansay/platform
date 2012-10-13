class ApiKey < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, :class_name => 'Doorkeeper::Application'
  attr_accessible :active, :request_token, :secret_token, :user_id, :application_id
  after_create :initialize_client_application

  def app_authorized?
    return false if application_id.nil?
    return self.application.authorized_applications.count > 0 && !secret_token.nil?
  end

  def authorize_app(site,password)
    return nil if application_id.nil?

    client_id = application.uid
    client_secret = application.secret
    redirect_uri = application.redirect_uri
    token = nil

    client = OAuth2::Client.new(client_id, client_secret, :site => site) 
    
    begin
      token = client.password.get_token(user.email, password)
    rescue Exception => e
      logger.error "DPLA: Resource Owner Credential FAILURE - #{application.uid} - #{e}"
    end
    
    self.update_attribute(:secret_token, token.token) unless token.nil? || token.expired?
    
    return token
  end
  
private
  def initialize_client_application
    user_client_app = Doorkeeper::Application.create(:name => "Test Client App")
    user_client_app.redirect_uri = "https://changeme:555" #Because we can't do mass assignment with current doorkeeper gem
    user_client_app.save
    self.application_id = user_client_app.id
    self.save
 end

end
