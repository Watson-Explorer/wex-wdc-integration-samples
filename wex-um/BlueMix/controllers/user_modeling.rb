
class UserModelingController < ApplicationController

 
  get '/model_tweets/for/:handle' do
    handle = params[:handle]
    tweets = find_tweets_for_user(handle)
    calculate_model(tweets)
  end

  post '/model_text/' do
    body = JSON.load(request.body)
    text = format_text_to_model(body["text"])
    calculate_model(text)
  end

  post '/visualize_text/' do
    body = JSON.load(request.body)
    text = format_text_to_model(body["text"])

    model = JSON.parse(calculate_model(text))
    visualize_model(model)
  end

  get '/visualize_tweets/for/:handle' do
    handle = params[:handle]
    tweets = find_tweets_for_user(handle)
    
    model = JSON.parse(calculate_model(tweets))
    visualize_model(model)
  end


end



