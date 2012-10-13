Feature: API Key Assignment
   
    Background:
      Given the following user exists:
        | email                    | password | password_confirmation |
        | mrtestuser_apikey@somedomain.com | testpass   | testpass                  |
      When I go to the homepage
      And I follow "Sign In"
      And I log in with the following:
        | Email    | Password |
        | mrtestuser_apikey@somedomain.com | testpass                  |
    
    Scenario: user without API Key
      Then I should see "Connecting to the DPLA API is as simple as 1-2-3"
      Then I should see "Register your application"

    Scenario: Request an API key
      And I click button "Register your application" 
      Then I should create an App for user with login "mrtestuser_apikey@somedomain.com"
      And I should see "Application Id:"
      And I should see "Secret:"

    Scenario: Request access  token
      Given I have an API Key
      Given I do not have an Access Token
      Then I should see "Request Access Token"
      And I click button "Request Access Token"
      Then I should have an authorized app 
      And I should see "Access Token:"

    Scenario: user with API Key
      Given I have an API Key
      Given I have an Access Token
      Then I should see "You are ready to use the API"
  
    Scenario: oauth admin section
      Given I am not an admin
      Then I should not be able to see the oauth admin page
