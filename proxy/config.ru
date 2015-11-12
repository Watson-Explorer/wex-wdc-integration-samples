require 'sinatra'
require 'excon'

require 'json'

# set :public_folder, './public'
# set :views, './views'

set :personality_insights_endpoint, "http://YOUR_PI_MODELING_ENDPOINT.mybluemix.net/pi/"
set :translation_endpoint, "http://YOUR_MACHINE_TRANSLATION_ENDPOINT.mybluemix.net/resources/translate"
set :relationship_extraction_endpoint, "http://YOUR_RELATIONSHIP_EXTRACTOR_ENDPOINT.mybluemix.net/api/extract"


require './lib/proxy'

run Sinatra::Application
