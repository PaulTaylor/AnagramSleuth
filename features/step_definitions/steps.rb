When(/^I visit "([^"]*)"$/) do |arg1|
  visit "/"
end

Then(/^I should see "([^"]*)"$/) do |arg1|
  expect(page).to have_content(arg1)
end

Then(/^I should not see "([^"]*)"$/) do |arg1|
  expect(page).not_to have_content(arg1)
end

When(/^I enter "([^"]*)" into "([^"]*)"$/) do |arg1, arg2|
  fill_in(arg2, :with => arg1)
end

When(/^Submit the "([^"]*)" form$/) do |arg1|
  within(:css, "##{arg1}") do
    click_button('Submit')
  end
end
