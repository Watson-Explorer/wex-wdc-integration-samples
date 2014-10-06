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
  
  def self.get_endpoint_for(service_name)
     rack_env = "RACK_ENV"   

     endpoint = Hash.new

     if ENV.key?(rack_env) && ENV[rack_env] == "production"
       service_info = JSON.parse(ENV["VCAP_SERVICES"])
       credentials = service_info[service_name].first["credentials"]

       endpoint[:url] = credentials["api_url"]
       endpoint[:username] = credentials["username"]
       endpoint[:password] = credentials["password"]
      
     else
        endpoint[:url] = "dev_server"
        endpoint[:username] = "dev_username"
        endpoint[:password] = "dev_password"
     end

     endpoint
  end



  configure do
     # set :views, 'views'
     #enable :sessions

     about = {
       :application => "Watson User Modeling / Watson Explorer Sample Integration API",
       :version => 0.1,
       :copyright => "Copyright IBM 2014",
       :contact => "http://ibm.com"
     }

     set :about, about

     # get the endpoint, username, and password
     endpoint_info = get_endpoint_for("systemudemoapisl-prod")
     set :endpoint, endpoint_info
   end

end