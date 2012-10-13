When /^I go to the homepage$/ do
    visit("/")
end

Then /^I should see "(.*?)"$/ do |arg1|
    expect(page).to have_content(arg1)
end

Then /^I should not see "(.*?)"$/ do |arg1|
   expect(page).not_to have_content(arg1)
end


When /^I follow "(.*?)"$/ do |arg1|
    click_link arg1
    expect(page).to have_content "Email"
end


When /^I fill in the following signup information:$/ do |table|
  table.hashes.each do |hash|
    fill_in "Email", :with => hash["Email"]
    fill_in "Password", :with => hash["Password"]
    fill_in "Password confirmation", :with => hash["Password confirmation"]
  end
end

When /^I fill in the following:$/ do |table|
  table.hashes.each do |hash|
    fill_in "Email", :with => hash["Email"]
    fill_in "Password", :with => hash["Password"]
  end
end

When /^I press "(.*?)"$/ do |arg1|

    click_on arg1
    
end


Given /^the following user exists:$/ do |table|
    table.hashes.each do |attributes|
      expect { User.create!(attributes)}.to change(User, :count).by(1)
    end
end

When /^I log in with the following:$/ do |table|
    visit "/"
    click_link "Sign In"
    table.hashes.each do |hash|
        fill_in "Email", :with => hash["Email"]
        fill_in "Password", :with => hash["Password"]
    end
    click_button "Sign in"
end

And /^I click button "(.*?)"$/ do |arg1|
  click_button(arg1)
end

Then /^I should create an App for user with login "(.*?)"$/ do |arg1|
  user= User.find_by_email(arg1)
  api_key = ApiKey.create(:user_id => user.id)
  expect(api_key.application_id).to_not eq(nil)
end

Given /^I have an API Key$/ do
  user = User.last
  user.create_api_key if user.api_key.nil?
  expect(user.api_key.nil?).to be(false)
end

Given /^I do not have an Access Token$/ do
  user = User.last
  user.create_api_key if user.api_key.nil?
  expect(user.api_key.secret_token).to be(nil)

end

Given /^I am not an admin$/ do
pending # express the regexp above with the code you wish you had
end

Then /^I should not be able to see the oauth admin page$/ do
pending # express the regexp above with the code you wish you had
end

Then /^I should have an authorized app$/ do
  expect(User.last.api_key.app_authorized?).to be(true)
end

Given /^I have an Access Token$/ do
  api_key = User.last.api_key
  api_key.authorize_app("http://test.com","testpass")
binding.pry
expect(api_key.secret_token.nil?).to be(false)
end
