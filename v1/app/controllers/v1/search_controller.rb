require_dependency "v1/application_controller"
require 'v1/item'

module V1
  class SearchController < ApplicationController

    doorkeeper_for :all
    
    def items
      results = V1::Item.search( params )
      render :json => results.to_json
    end
    
    def links
    end
    
    def index
    end
  end
end
