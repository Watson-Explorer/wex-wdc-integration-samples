require 'sinatra/base'

Dir.glob('./helpers/*.rb').each { |file| require file }
require './controllers/application_controller.rb'
Dir.glob('./controllers/*.rb').each { |file| require file }



# load controllers and map to base routes
map('/pi/') { run PersonalityInsightsController }
map('/') { run ApiRunController }

