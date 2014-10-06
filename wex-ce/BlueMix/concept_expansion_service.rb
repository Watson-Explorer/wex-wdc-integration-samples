require 'sinatra'
require 'excon'
require 'json'


configure do
  service_name = "conceptexpansion"

  endpoint = Hash.new

  if ENV.key?("RACK_ENV") && ENV["RACK_ENV"] == "production"
   service_info = JSON.parse(ENV["VCAP_SERVICES"])
   credentials = service_info[service_name].first["credentials"]

   set :endpoint, credentials["services"].first[service_name]["baseendpoint"]
   set :username, credentials["userid"]
   set :password, credentials["password"]

  else
    set :endpoint, "dev_server"
    set :username, "dev_username"
    set :password, "dev_password"
  end
end



post '/expand/concepts/?' do
   data = JSON.load(request.body)
   
   max_tries = 50
   max_tries = data["max_tries"] if data.key? "max_tries"
   
   wait_time = 1
   wait_time = data["wait_time"] if data.key? "wait_time"


   if !isUp
      return {
        :error => "Couldn't connect to backing Watson Service. :("
       }.to_json
   end

   job_id = uploadList(data)

   if !job_id.key? "jobid"
    return {
      :error => "Expansion job could not be uploaded and started by the service.",
      :response => job_id
     }.to_json
   end

   puts "Job ID = " + job_id.to_s

   job_state = getStatus(job_id)
   puts "Job state = " + job_state
   STDOUT.flush

   tries = 0
   while job_state != 'D' && job_state != 'F' && tries < max_tries
    sleep(wait_time) # wait 1 second before trying again

    job_state = getStatus(job_id)
    puts "Job state = " + job_state
    STDOUT.flush

    tries += 1
   end

   if tries == max_tries
     return {:error => "Exceeded wait limit for the service." }.to_json
   elsif job_state == 'F'
     return {:error => "Job failed in the service." }.to_json
   end

   getResult(job_id)
end



helpers do

  def isUp
    response = Excon.get(settings.endpoint + "/ping",
                         :user => settings.username,
                         :password => settings.password)
    return response.status == 200
  end


  def uploadList(data)
    # data[:dataset] = "mtsamples"  # hard coding to the medical transcripts training set
    headers = {
        "Content-Type" => "application/json"
    }

    response = Excon.post(settings.endpoint + "/upload",
                          :body => data.to_json,
                          :headers => headers,
                          :user => settings.username,
                          :password => settings.password)

    JSON.load(response.body)
  end


  def getStatus(job_id)
    headers = {
        "Content-Type" => "application/json"
    }

    response = Excon.get(settings.endpoint + "/status",
                         :query => job_id,
                         :headers => headers,
                         :user => settings.username,
                         :password => settings.password)

    JSON.load(response.body)["state"]
  end


  def getResult(job_id)
    headers = {
        "Content-Type" => "application/json"
    }

    response = Excon.put(settings.endpoint + "/result",
                          :body => job_id.to_json,
                          :headers => headers,
                          :user => settings.username,
                          :password => settings.password)

    puts response.body
    STDOUT.flush

    response.body
  end

end


