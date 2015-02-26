class ApiRunController < ApplicationController

  get '/' do
    @default_data = "Called upon to undertake the duties of the first executive office of our country, I avail myself of the presence of that portion of my fellow-citizens which is here assembled to express my grateful thanks for the favor with which they have been pleased to look toward me, to declare a sincere consciousness that the task is above my talents, and that I approach it with those anxious and awful presentiments which the greatness of the charge and the weakness of my powers so justly inspire. A rising nation, spread over a wide and fruitful land, traversing all the seas with the rich productions of their industry, engaged in commerce with nations who feel power and forget right, advancing rapidly to destinies beyond the reach of mortal eye -- when I contemplate these transcendent objects, and see the honor, the happiness, and the hopes of this beloved country committed to the issue and the auspices of this day, I shrink from the contemplation, and humble myself before the magnitude of the undertaking. Utterly, indeed, should I despair did not the presence of many whom I here see remind me that in the other high authorities provided by our Constitution I shall find resources of wisdom, of virtue, and of zeal on which to rely under all difficulties. To you, then, gentlemen, who are charged with the sovereign functions of legislation, and to those associated with you, I look with encouragement for that guidance and support which may enable us to steer with safety the vessel in which we are all embarked amidst the conflicting elements of a troubled world."

    @function = params[:api_function]
    @data = params[:data]

    if @function.nil? || @data.nil?
      @function = "text"
      @data = @default_data
    
    elsif @function.empty? || @data.empty?
      @function = "text"
      @data = @default_data
    
    else
      if @function == "text"
        @endpoint = request.base_url + "/pi/model_text/"
        
        @body = { :text => @data }
        headers = { "Content-Type" => "application/json" }

        response = Excon.post(@endpoint, :body => @body.to_json, :headers => headers)
        @result = response.body
                
      elsif @function == "twitter"
        @endpoint = request.base_url + "/pi/model_tweets/for/#{@data}"
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



