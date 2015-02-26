module ApiHelpers

 def format_text_to_model(text_to_model)
      data = [{
         :contenttype => "text/plain",
         :sourceid => "wex",
         :userid => "anon",
         :language => "en",
         :content => text_to_model,
         :id => "wex_id" #uniq Id for the content being analyzed.  Might be a URL or GUID
      }]

      data
   end


   def find_tweets_for_user(handle)
    config = {
      :consumer_key    => settings.twitter_api_key,
      :consumer_secret => settings.twitter_api_secret
    }

    max_fetches = 5

    client = Twitter::REST::Client.new(config)

    options = {
      :count => 200,
      :include_rts => false
    }


    messages_to_model = []

    puts "fetching tweets.."
    tweets = client.user_timeline(handle, options)

    fetch_count = 0
    while not tweets.empty? and 
          fetch_count < max_fetches and
          messages_to_model.length < 200 do
      messages_to_model << tweets.map do |t|
        message = Hash.new
        message[:id] = t.id.to_s
        message[:created] = t.created_at.to_i
        message[:content] = t.text
        message[:contenttype] = "text/plain"
        message[:sourceid] = "Twitter"
        message[:language] = t.lang
        message[:userid] = handle

        message
      end
      
      messages_to_model.flatten!

      puts "Got #{messages_to_model.length} so far. Fetching more tweets.."

      fetch_count += 1
      if fetch_count == max_fetches then break end
      
      options[:max_id] = tweets.last.id
      tweets = client.user_timeline(handle, options)
    end

    puts "Fetched #{messages_to_model.length} status updates for #{handle}."

    messages_to_model

    # catch the exception for a handle that does not exist
   rescue Twitter::Error::NotFound => error
     puts error.message
     { :error => error.message }

    # catch the exception for too many requests.  Should just fail immediately, no retry
   rescue Twitter::Error::TooManyRequests => error
     puts error.message
     { :error => error.message }

   end


   def calculate_model(data)
      payload = { :contentItems => data }

      function = "/v2/profile"
      response = post(settings.endpoint[:url] + function,
                      settings.endpoint[:username],
                      settings.endpoint[:password],
                      payload)
      response
   end



   def post(url, username, password, payload)
     headers = {
        "Content-Type" => "application/json"
     }

     response = Excon.post(url, 
                          :body => payload.to_json,
                          :headers => headers,
                          :user => username,
                          :password => password)

    response.body

  rescue => e
    puts "Something went wrong communicating with backend service..."
    puts e.message
    puts e.backtrace
    {
      :message => "Something went wrong communicating with backend service...", 
      :error => e.message,
      :backtrace => e.backtrace
    }.to_json
  end

end
