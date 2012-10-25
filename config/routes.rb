Dpla::Application.routes.draw do

  mount Doorkeeper::Engine => '/oauth'

  devise_for :users

  root :to => "home#index"
  
  resources :api_keys

  mount V1::Engine => "/api/v1"

end
