$:.unshift(File.expand_path('../../lib', __FILE__))
 
require 'sinatra/base'
require 'json'
require 'excon'
require 'twitter'


class ApplicationController < Sinatra::Base
 
  helpers ApiHelpers

  set :views, File.expand_path('../../views', __FILE__)
  set :public_folder, File.expand_path('../../public/', __FILE__)

  
  set :twitter_api_key, "ENTER API KEY HERE"
  set :twitter_api_secret, "ENTER API SECRET HERE"  # you shouldn't really do this as it's not that
                                                    # secure, but for a demo, it's at least excusable...  
  
  def self.get_endpoint
    rack_env = "RACK_ENV"

    service_name = "personality_insights"
    credentials_env = "credentials"
    url_env = "url"
    user_env = "username"
    password_env = "password"

    endpoint = Hash.new

    if ENV.key?(rack_env) && ENV[rack_env] == "production"
     service_info = JSON.parse(ENV["VCAP_SERVICES"])
     credentials = service_info[service_name].first[credentials_env]

     endpoint[:url] = credentials[url_env]
     endpoint[:username] = credentials[user_env]
     endpoint[:password] = credentials[password_env]
    
    else # for dev, take the endpoints from environement variables, assumes Bluemix has been configured for remote testing
     endpoint[:url] = ENV['bluemix_endpoint'] ? ENV['bluemix_endpoint'] : "endpoint"
     endpoint[:username] = ENV['bluemix_username'] ? ENV['bluemix_username'] : "username"
     endpoint[:password] = ENV['bluemix_password'] ? ENV['bluemix_password'] : "password"
    end

    endpoint
  end



  configure do
     # set :views, 'views'
     #enable :sessions

     about = {
       :application => "Watson Personality Insights / Watson Explorer Sample Integration API",
       :version => 0.1,
       :copyright => "Copyright IBM 2015",
       :contact => "http://www.ibm.com/smarterplanet/us/en/ibmwatson/explorer.html"
     }

     set :about, about

     # get the endpoint, username, and password
     endpoint_info = get_endpoint
     set :endpoint, endpoint_info
   end

end