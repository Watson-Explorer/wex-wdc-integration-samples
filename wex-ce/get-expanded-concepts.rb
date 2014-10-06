require 'excon'
require 'json'
require 'optparse'


input = nil
output = "out.txt"
endpoint = "http://PUT_YOUR_DEFAULT_ENDPOINT_HERE.mybluemix.net/"

payload = Hash.new
payload[:label] = "Some Label"
payload[:max_tries] = 60
payload[:wait_time] = 1
payload[:dataset] = "mtsamples"

# Command line options set up...

OptionParser.new { |opts|
   opts.banner = "Usage: #{File.basename($0)} -i input [options]"

   opts.on('-i input', '--in input', "Path to newline seperated file that will be the input.") do |arg|
      input = arg
   end

   opts.on('-e endpoint', '--endpoint endpoint', "The base endpoint hosting the BlueMix web service, e.g. http://wex-ce.mybluemix.net/") do |arg|
      endpoint = arg
   end

   opts.on('-o output', '--out output', "Optional. Path to file where the results should be written.") do |arg|
      output = arg
   end

   opts.on('-l label', '--label label', "Optional. Label applied to the cocnept set.") do |arg|
      payload[:label] = arg
   end

   opts.on('-d name', '--dataset name', "Optional. Name of the dataset to use. mtsamples or twitter") do |arg|
      payload[:dataset] = arg
   end

   opts.on('-w seconds', '--wait seconds', "Optional. Time in seconds that the service should delay between tries.") do |arg|
      payload[:wait_time] = arg.to_i
   end

   opts.on('-t count', '--tries count', "Optional. Number of times the service should attempt to fetch results before giving up.") do |arg|
      payload[:max_tries] = arg.to_i
   end

}.parse!


# Command line options error checking...

errors = false
if input.nil?
   puts "Input file is required!"
   errors = true
end

if payload[:wait_time] <= 0
   puts "Wait time should be a number greater than 0."
   errors = true
end

if payload[:max_tries] <= 0
   puts "Tries count should be a number greater than 0."
   errors = true
end

if !endpoint =~ /\A#{URI::regexp(['http', 'https'])}\z/
   puts "The endpoint should be a valid URL.  For example, http://wex-ce.mybluemix.net"
end

exit if errors


# ---------------------------------------
# Read the file of seeds and make an HTTP request
# to the BlueMix endpoint.

payload[:seeds] = Array.new
File.readlines(input).each do |line|
   payload[:seeds] << line
end

uri = URI.parse(endpoint)
endpoint_builder = {
  :host => uri.host,
  :port => uri.port,
  :scheme => uri.scheme,
  :path => '/expand/concepts/'
}

url = URI::HTTP.build(endpoint_builder).to_s

puts "Posting to #{url}..."

headers = { "Content-Type" => "application/json" }

response = Excon.post(url, :headers => headers, :body => payload.to_json)
results = JSON.parse(response.body, :symbolize_names => true)

if results.key? :error
  puts results[:error]
  puts ""
  puts results[:message]
  exit
end


# -----------------------------
# Write the results out to a file...

out = File.new(output, 'w')

out.puts "<thesaurus language='english' domain='#{payload[:label]}'>"

# iterate through each of the input seeds
# create a thesarus that relates the provided
# terms to the input seeds list
# The generated dictionary can be crawled as an Ontolection
# in wex. While this application of the data returned by the
# Watson service is not necessarily directly applicable in this 
# way it's a fairly close match to functionality within wex.
payload[:seeds].each do |seed_word|
  out.puts "   <word name='#{seed_word.chomp}'>"
  
  results[:return_seeds].each do |seed|
     # For some reason the service substitutes all special characters with
     # this zZzperiodzZz or zZzcommazZz nonsense. Just strip it all out...
     term = seed[:result].gsub(/zZz.+zZz/, "").gsub(/\s+/, ' ')
     out.puts "      <related weight='#{seed[:prevalence]}'>#{term}</related>"

  end
  
  out.puts "   </word>"
end

out.puts"</thesaurus>"

out.close

puts "Results saved to #{output}"