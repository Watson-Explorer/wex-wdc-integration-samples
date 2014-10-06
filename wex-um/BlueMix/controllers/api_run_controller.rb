class ApiRunController < ApplicationController

  get '/' do
    @function = params[:api_function]
    @data = params[:data]

    if @function.nil? || @data.nil?
      @function = "text"
      @data = "This is some text that will be analyzed."
    
    elsif @function.empty? || @data.empty?
      @function = "text"
      @data = "test data"
    
    else
      if @function == "text"
        @endpoint = request.base_url + "/um/model_text/"
        
        @body = { :text => @data }
        headers = { "Content-Type" => "application/json" }

        response = Excon.post(@endpoint, :body => @body.to_json, :headers => headers)
        @result = response.body
                
      elsif @function == "twitter"
        @endpoint = request.base_url + "/um/model_tweets/for/#{@data}"
        response = Excon.get(@endpoint)
        @result = response.body

      elsif @function == "visualize_text"
        @endpoint = request.base_url + "/um/visualize_text/"
        @body = { :text => @data }
        headers = { "Content-Type" => "application/json" }

        response = Excon.post(@endpoint, :body => @body.to_json, :headers => headers)
        @result = response.body

      elsif @function == "visualize_twitter"
        @endpoint = request.base_url + "/um/visualize_tweets/for/#{@data}"
        response = Excon.get(@endpoint)
        @result = response.body

      else
        @error = "Unknown or missing function."
      end
    end

    erb :api_run
  end


  get '/about' do
    settings.about
  end



  get '/environment' do
    # taken from basic Hello World! app
    @version = RUBY_VERSION
    @os = RUBY_PLATFORM
    @env = {}
    ENV.each do |key, value|
      begin
        hash = JSON.parse(value)
        @env[key] = hash
      rescue
        @env[key] = value
      end
    end
    
    appInfo = @env["VCAP_APPLICATION"]
    services = @env["VCAP_SERVICES"]

    erb :hi
  end


end



