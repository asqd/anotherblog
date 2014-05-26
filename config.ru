require 'bundler'
Bundler.require

require './blog.rb'

DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite://",settings.root,"dev.db"))

run Sinatra::Application
