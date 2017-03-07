require 'capybara'
require 'capybara/cucumber'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

require './main.rb'
Capybara.app = Sinatra::Application
