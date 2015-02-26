require 'sinatra'
require 'excon'

require 'json'

# set :public_folder, './public'
# set :views, './views'

set :qa_endpoint, "http://YOUR_QA_ENDPOINT.mybluemix.net/resources/question/"
set :personality_insights_endpoint, "http://YOUR_PI_MODELING_ENDPOINT.mybluemix.net/pi/"
set :translation_endpoint, "http://YOUR_MACHINE_TRANSLATION_ENDPOINT.mybluemix.net/resources/translate"
set :relationship_extraction_endpoint, "http://YOUR_RELATIONSHIP_EXTRACTOR_ENDPOINT.mybluemix.net/api/extract"
set :message_resonance_endpoint, "http://YOUR_MESSAGE_RESONANCE_ENDPOINT.mybluemix.net/resources/resonate"


require './lib/proxy'

run Sinatra::Application
