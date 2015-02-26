# Expected input:
#   JSON object in the request body
#   {
#      "question" : "The question to ask of Watson Q&A"
#   }
post '/qa/ask/' do
   data = JSON.load(request.body)

   body = URI.encode_www_form(:question => data["question"])
   headers = {
      "Content-Type" => "application/x-www-form-urlencoded"
   }

   response = Excon.post(settings.qa_endpoint, :body => body, :headers => headers)

   response.body
end



# Expected input:
#   JSON object in the request body
#   {
#      "text" : "The text from which the user model should be created"
#   }
post '/pi/model_text/' do
   data = JSON.load(request.body)

   url = "#{settings.personality_insights_endpoint}model_text/"
   body = { :text => data["text"] }
   headers = {
      "Content-Type" => "application/json"
   }

   response = Excon.post(url, :body => body.to_json, :headers => headers)

   response.body
end


# Expected input:
#   JSON object in the request body
#   {
#      "text" : "The text from which the user model should be created"
#   }
post '/pi/visualize_text/' do
   data = JSON.load(request.body)

   url = "#{settings.personality_insights_endpoint}visualize_text/"
   body = { :text => data["text"] }
   headers = {
      "Content-Type" => "application/json"
   }

   response = Excon.post(url, :body => body.to_json, :headers => headers)

   response.body
end



# Expected input:
#   JSON object in the request body
#   {
#      "handle" : "user_handle"
#   }
post '/pi/model_twitter/' do
   data = JSON.load(request.body)

   url = "#{settings.personality_insights_endpoint}model_tweets/for/#{data["handle"]}"
   response = Excon.get(url, :headers => headers)

   response.body
end



# Expected input:
#   JSON object in the request body
#   {
#      "handle" : "user_handle"
#   }
post '/pi/visualize_twitter/' do
   data = JSON.load(request.body)

   url = "#{settings.personality_insights_endpoint}visualize_tweets/for/#{data["handle"]}"
   response = Excon.get(url, :headers => headers)

   response.body
end





# Expected input:
#   JSON object in the request body
#   {
#      "text" : "the text to be translated"
#   }
post '/english/to/spanish/' do
   data = JSON.load(request.body)

   body = { 
      :sid => "mt-enus-eses",
      :textToTranslateArray => data["text"] 
   }

   body = URI.encode_www_form(body)
   
   headers = {
      "Content-Type" => "application/x-www-form-urlencoded"
   }

   response = Excon.post(settings.translation_endpoint, :body => body, :headers => headers)
   
   response.body
end


# Expected input:
#   JSON object in the request body
#   {
#      "text" : "the text to be translated"
#   }
post '/spanish/to/english/' do
   data = JSON.load(request.body)

   body = { 
      :sid => "mt-eses-enus",
      :textToTranslateArray => data["text"] 
   }
   
   body = URI.encode_www_form(body)
   
   headers = {
      "Content-Type" => "application/x-www-form-urlencoded"
   }

   response = Excon.post(settings.translation_endpoint, :body => body, :headers => headers)

   response.body
end




# Expected input:
#   JSON object in the request body
#   {
#      "text" : "The message text to be analyzed for impact"
#   }
post '/resonate/message/' do
   data = JSON.load(request.body)

   body = { :question => data["text"] }
   headers = {
      "Content-Type" => "application/json"
   }

   response = Excon.post(settings.message_resonance_endpoint, :body => body.to_json, :headers => headers)

   response.body
end


# Expected input:
#   JSON object in the request body
#   {
#      "text" : "The message text to annotate"
#   }
post '/re/' do
   data = JSON.load(request.body)

   body = URI.encode_www_form(:text => data["text"])
   headers = {
      "Content-Type" => "application/x-www-form-urlencoded"
   }

   response = Excon.post(settings.relationship_extraction_endpoint, :body => body, :headers => headers)

   { :annotations => response.body }.to_json
end



get '/' do
  erb :index
end