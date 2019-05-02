require 'capybara'
require 'capybara/cucumber'
#require 'capybara/poltergeist'

Capybara.javascript_driver = :selenium_chrome_headless

require './main.rb'
Capybara.app = Sinatra::Application
