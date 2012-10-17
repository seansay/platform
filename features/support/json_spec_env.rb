# features/support/json_spec_env.rb
require "json_spec/cucumber"

def last_json
  page.source 
end

def valid_json? json_  
  begin  
    JSON.parse(json_)  
    return true  
  rescue Exception => e  
    return false  
  end  
end
