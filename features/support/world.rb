module CukeApiHelper

  def item_query_to_json(params)
    visit(url"/api/v1/items?#{ params.to_param }")
    JSON.parse(page.source)
  end

  def valid_json? json_  
    begin  
      JSON.parse(json_)  
      return true  
    rescue Exception => e  
      return false  
    end  
  end

end

World(CukeApiHelper)
