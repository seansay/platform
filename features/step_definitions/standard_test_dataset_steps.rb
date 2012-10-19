Given /^the dataset exists$/ do
  expect(File.exist?(File.dirname(__FILE__) + "/../../v1/lib/v1/standard_dataset/item.json")).to be(true)
end

When /^I have invalid JSON in the standard test dataset$/ do
  @json = File.read(File.dirname(__FILE__) + "/../../v1/lib/v1/standard_dataset/item.json")
  @json += "..This Ain't Valid JSON{{Sure:Ain't{].."
end

Then /^I should get a dataset error$/ do
  expect(valid_json?(@json)).to be(false)
end

When /^I have valid JSON in the test dataset$/ do
  @json = File.read(File.dirname(__FILE__) + "/../../v1/lib/v1/standard_dataset/item.json")
end

Then /^I should not get a dataset error$/ do
  expect(valid_json?(@json)).to be(true)
end

Given /^there are (\d+) items that contain the word "(.*?)" in the "(.*?)"$/ do |arg1, arg2, arg3|
  @json = File.read(File.dirname(__FILE__) + "/../../v1/lib/v1/standard_dataset/item.json")
  dataset = JSON.parse(@json)
  matched_key_value_count = dataset.inject(0) {|count, el| count +=1 if el[arg3].scan(/#{arg2}/i).any?; count}
  expect(matched_key_value_count.to_s).to eq(arg1)
end

Given /^there is a metadata record "(.*?)" with "(.*?)" in the "(.*?)" field$/ do |arg1, arg2, arg3|
  @json = File.read(File.dirname(__FILE__) + "/../../v1/lib/v1/standard_dataset/item.json")
  dataset = JSON.parse(@json)
  grouped_dataset = dataset.group_by {|el| el["_id"]}
  expect(grouped_dataset.include?(arg1)).to be(true)
  expect(grouped_dataset[arg1][arg2]).to eq(arg3)
end
