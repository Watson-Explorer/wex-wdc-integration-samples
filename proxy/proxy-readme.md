# Application Builder Proxy

The Application Builder Proxy is a thin server side component that serves two important purposes.

1. The proxy is an abstraction between Application Builder widgets and web services that are external to Engine.  Calling the proxy instead of directly calling an external web service from widgets promotes better maintainability.  For example, when an external endpoint changes only the proxy must be updated rather than the URL references in individual widgets.

2. The proxy enables client-side interaction with external services via Ajax calls in the browser. Modern browser security prevents cross site Ajax requests due to the same-origin policy.


# Getting Started

A prepackaged WAR is provided, ready to deploy to an existing installation of IBM Watson Content Explorer Application Builder (App Builder for short). The App Builder Proxy WAR will be deployed to all App Builder servers (which run on the IBM Websphere application server by default).  The proxy is installed with the following steps.

$AB_HOME refers to the home folder for the specific Application Builder installation.  For example, on a default Windows installation, `$AB_HOME` might be C:\Program Files\IBM\IDE\AppBuilder

Create a new folder called 'proxy' in `$AB_HOME/wlp/usr/servers/AppBuilder/apps`

Unzip the proxy WAR into the newly created proxy folder.  You should now have `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/META-INF` and `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/WEB-INF`.

Open server.xml, located at $AB_HOME/wlp/usr/servers/AppBuilder/ for editing.  Add the following block to the `server` node.


```xml
   <application type="war" id="proxy" name="proxy" location="${server.config.dir}/apps/proxy">
   </application>
```


Before using the App Builder Proxy it is necessary to update the proxy configuration so that the Watson services endpoints point to your specific BlueMix application endpoints.  All endpoint URLs are defined in `config.ru` located in `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/WEB-INF`.

Restart Application Builder's WebSphere according to the App Builder documentation - by restarting the Application Builder service using the normal commands for your installation.


# Usage

A web page for testing the proxy and demonstrating the basics for how it works is provided.  This web page can be accessed at http://localhost:9080/proxy (change the port or hostname as appropriate specific to your sever).  From this test page you can run the provided proxy services, review the inputs for each proxy function, and see the output that is returned.

The proxy provides helper functions that can easily be called from within an App Builder widget or through an Ajax request in JavaScript running in the browser.  Generally speaking, it is better to use the proxy from within App Builder widgets than to call out directly to a BlueMix (or other) external service.

Here is an example for how to call the proxy from a Custom (ERB) widget in App Builder.  This example code calls the Personality Insights proxy from an ERB widget.


```HTML+ERB
<%
require 'net/http'

# Determine the endpoint for the proxy
# This assumes that the proxy is deployed 
# to the same server as the current App Builder.

origin = URI.parse(request.original_url)
endpoint_builder = {
  :host => origin.host,
  :port => origin.port,
  :scheme => origin.scheme,
  :path => '/proxy/pi/model_text/'  
}

url = URI::HTTP.build(endpoint_builder)

data = {
  :text => "This is some sample text to see what will happen when I hit the service through the proxy in a widget."
}.to_json

req = Net::HTTP::Post.new(url.to_s)
req.body = data
req.content_type = 'content/json'

response = Net::HTTP.start(url.hostname, url.port) do |http|
  http.request(req)
end

model = JSON.parse(response.body)
%>

<%= model %>
```


This snippet shows how you can call the same personality insights proxy from a browser-side Ajax call using jQuery (included by default in App Builder).  Be sure to to bind events to elements that exist in the DOM by using the standard jQuery binding methods (e.g. set your event bindings when the onLoad event is called or using delegates, etc.).


```JavaScript
$.ajax({
   type: "POST",  // all methods use POST
   url: "/proxy/pi/model_text/",
   data: JSON.stringify(the_json_data_for_this_method),  // all methods take a JSON object in the body of the request
   success: function(response) {
      response = JSON.parse(response);
      console.log(response);
   },
   failure: function(error) {
      console.log(error);
   }
});
```

## Default Proxy Methods

All proxy methods accept a JSON object in the body of the request.  The examples above show the proper way to create and use JSON in this context.  Remember that the proxy is just a lightweight pass through and that all major processing will be taking place in the Watson Developer Cloud applications and services.

### Watson Q&A

Returns answers and evidence for a given question.  See [Watson QAAPI Proxy Service](wex-qa/watson-qa-readme.md) for more information.

Endpoint: `proxy/qa/ask/`

Request Body:
```json
{
  "question" : "The question to ask of Watson Q&A"
}
```

### Personality Insights

Returns a JSON object containing analysis.  See [Personality Insights Proxy Service](wex-personality-insights/watson-personality-insights-readme.md) for more information.

#### Model Text

Endpoint: `proxy/pi/model_text/`

```json
{
  "text" : "The text from which the model should be created."
}
```

#### Twitter using a Twitter Handle

Endpoint: `proxy/pi/model_twitter/`

```json
{
  "handle" : "user_handle"
}
```

### Machine Translation
Translates text to and from English and Spanish.  See [Machine Translation Proxy Service](wex-mt/watson-machine-translation-readme.md) for more information.


#### English to Spanish
Endpoint: `proxy/english/to/spanish/`

```json
{
  "text" : "the text to be translated."
}
```

#### Spanish to English

Endpoint: `proxy/spanish/to/english/`

```json
{
  "text" : "el texto a traducir."
}
```


### Message Resonance
Returns resonance scores for given text.  See [Message Resonance Proxy Service](wex-mr/watson-message-resonance-readme.md) for more information.

Endpoint: `proxy/resonate/message/`

```json
{
  "text" : "The message text to be analyzed for impact."
}
```

### Relationship Extraction
Extracts generic entities (e.g. person, place, thing, organization, country, ...) and returns annotated text.  See [Relationship Extraction Proxy Service](wex-re/watson-re-readme.md) for more information.

Endpoint: `proxy/re/`

```json
{
  "text" : "The message text from which information will be extracted."
}
```


# Modifying the Proxy

The most common modification that may be required to the proxy is to add new routes to the proxy.  As long as no new ruby gems are required it is possible to modify the proxy directly.  This can be done by updating `proxy.rb` located in `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/WEB-INF/lib`.

The proxy uses [Ruby Sinatra](http://www.sinatrarb.com/) to provide a REST style web service interface.  Further information on Sinatra development is [available on the web](http://www.sinatrarb.com/intro.html).

Once your changes are complete, restart Application Builder's WebSphere using the normal methods.


## Bundling a new WAR

If new gems or other Java libraries are required, or if you want to package the proxy into a new WAR for any reason, you will need to set up a basic development environment for [JRuby](http://www.jruby.org/).  Ruby was chosen for the ease of implementation (using frameworks such as Sinatra) and to allow for modifications to be made in the proxy without requiring code to be recompiled.

The proxy assumes `JRuby 1.7.18` for deployment but it might be possible to test the application in native `Ruby 1.9.3`.  The simplest approach is to use JRuby for development, testing, and deployment.

The following JRuby Gems are required to get started.

* [Bundler](http://bundler.io/)
* [Warbler](https://github.com/jruby/warbler)


First install required gems.


```
$> bundle install
```


Now the proxy can be run as a rack application for testing and development purposes.


```
$> rackup -p4567
```


At this point the proxy will be running at http://localhost:4567.

The WAR can be created using Warbler.  If adding new gems be sure that the gems are installed under JRuby and the `Gemfile` is fully up to date.  A rake task is available to Warble the proxy application.  The rake task should be used so that specific JARs required for proper operation in WebSphere are copied to the correct path locations within the generated WAR.  The rake task requires that `unzip` and either `jar` or `zip` are in your path.  On Linux and Mac OS these tools should be available by default.  On Windows it's simplest to run the rake task through [Git Bash](http://www.git-scm.com/), [MinGW](http://mingw.org/), or [Cygwin](https://cygwin.com/).  Another alternative on Windows is to install the [GNU Zip](http://gnuwin32.sourceforge.net/packages/zip.htm) and [Unzip](http://gnuwin32.sourceforge.net/packages/unzip.htm) utilities and use the standard CMD prompt or Powershell.  It is assumed that the Java bin folder is on your path.


```
$> rake -f warble.rake
```

There could be minor variations in the JRuby file names from one version to another.  If you run into problems running the rake task you may need to update the script based on the version of JRuby you are running.  When we moved from 1.7.13 to 1.7.18 the file names were pretty obvious and the changes trivial.  Pull requests are welcome.