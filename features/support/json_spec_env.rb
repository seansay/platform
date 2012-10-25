# features/support/json_spec_env.rb

def valid_json? json_  
  begin  
    JSON.parse(json_)  
    return true  
  rescue Exception => e  
    return false  
  end  
end
