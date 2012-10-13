Doorkeeper.configure do
  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |routes|
    # Put your resource owner authentication logic here.
    current_user || warden.authenticate!(:scope => :user)
  end

  resource_owner_from_credentials do |routes|
    u = User.find_for_database_authentication(:email => params[:username])
    u if u && u.valid_password?(params[:password])
  end
  
  # If you want to restrict the access to the web interface for
  # adding oauth authorized applications you need to declare the
  # block below
  admin_authenticator do |routes|
    # Put your admin authentication logic here.
    # If you want to use named routes from your app you need
    # to call them on routes object eg.
    # routes.new_admin_session_path
    #authenticate_admin_user!
    raise SecurityError unless session["warden.user.user.key"].include?([1])
  end

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  access_token_expires_in nil

  # Issue access tokens with refresh token (disabled by default)
  # use_refresh_token

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  # default_scopes  :public
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from `HTTP_AUTHORIZATION` header and
  # fallsback to `:client_id` and `:client_secret` from `params` object
  # Check out the wiki for mor information on customization
  client_credentials :from_basic, :from_params
end
