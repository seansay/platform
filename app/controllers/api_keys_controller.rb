class ApiKeysController < ActionController::Base
  before_filter :authenticate_user!

  def create
    current_user.build_api_key if current_user.present?
    if current_user.api_key.save && current_user.api_key.application_id.present?
      status = 200
      application = current_user.api_key.application
      api_key_id = current_user.api_key.id
      return_data = {
        :message => "Great Success! Your request to register an app to acess the DPLA API was granted.",
        :application => application,
        :apiKeyId => api_key_id
      }
    else
      status = 403
      return_data = {:message => "There was a problem processing this request. Please try again later."}
    end

    render :json => return_data.to_json, :status => status

  end

  def update
    return_data = {:message => "There was a problem requesting your access token. Check your password and try again."}
    status = 403
    if params[:authorize].present?
      api_key = ApiKey.find(params[:id])
      token = api_key.authorize_app(root_url, params[:password])
      if !token.nil?
        return_data = {:message => "Your Access Token Has Been Granted", :token => token.token}
        status = 200
      end
    end
    render :json => return_data.to_json, :status => status
  end

  def index
    render :layout => "application"
  end
end
