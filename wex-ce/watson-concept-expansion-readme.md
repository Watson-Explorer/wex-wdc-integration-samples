# Using Watson Concept Expansion Service with Watson Explorer

The [Watson Concept Expansion Service](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/concept-expansion.html) determines the conceptual context of a given set of seed words or phrases and provides additional words or phrases that expand on the concept. The current Watson Concept Expansion Service has two training data sets available: medical transcriptions and random status updates from Twitter. The generated concept expansion is useful for gaining insights into a domain beyond the information available within the context of a single document or corpus.

In the context of Watson Explorer, the most obvious use cases are to apply concept expansion information with query expansion and to assist with choosing trigger terms for use with spotlights.  Both of these use cases are tactics for tuning search relevancy.

The goal of this tutorial is to demonstrate how to get started with an integration between Watson Explorer and the Watson Concept Expansion service available on IBM Bluemix. By the end of the example you will have an operational service that you can access through a command line tool.  The output of this command line tool might be used to create ontolections in Watson Explorer Engine, or to improve trigger words for spotlights in Watson Explorer Results Module.  Both relevancy tuning strategies can be used to improve search through Application Builder.


## Prerequisites
Please see the [Introduction](/README.md) for an overview of the integration architecture, and the tools and libraries that need to be installed to create Ruby-based applications in Bluemix. This prerequisite is required to run the local command line tool, which is written in Ruby.

- An [IBM Bluemix](https://ace.ng.Bluemix.net/) account
- [Watson Explorer](http://www-01.ibm.com/support/knowledgecenter/SS8NLW_10.0.0/com.ibm.swg.im.infosphere.dataexpl.install.doc/c_install_wrapper.html) - Installed, configured, and running



## What's Included in this Tutorial

This tutorial will walk through the creation of a Bluemix based web service that uses Watson Concept Expansion.  For the purposes of this example, the web service is exercised through the use of a command line tool that generates XML output suitable for ingestion as a query expansion ontology in Watson Explorer.


## Step-by-Step Tutorial

This section outlines the steps required to configure and deploy a custom Bluemix Concept Expansion web service.

   
### Configuring and Deploying the Bluemix Custom Watson Concept Expansion Web Service

The example Bluemix application uses a `manifest.yml` file to specify the application name, services bindings, and basic application settings.  Using a manifest simplifies distribution and deployment of CloudFoundry applications (for example, Bluemix).  Since the example application is written in Ruby, the code can be deployed to Bluemix as-is. Ruby will be required to run the provided command line tool that uses the deployed web service.

If you have not done so already, sign in to Bluemix.

```
$> cf api api.ng.Bluemix.net
cf login
```


Once you are signed in, you will need to create the Watson User Modeling service that the example application will bind to.  In this example, we're calling the service `wex-ce`. This name is already set in the `manifest.yml`.  Since services might be used by multiple applications, this name isn't ideal (a more descriptive name can improve maintainability), but it's suitable for this example.

```
$> cf create-service "conceptexpansion" Free wex-ce
```


Next, deploy the application to your space in the Bluemix cloud.  If this is the first time deploying, the application will be created for you.  Subsequent pushes to Bluemix will overwrite the previous instances you have deployed.

```
$> cf push
```


Once the application has finished restarting, you should now be able to run a test using the provided Ruby command line tool.

To do that you'll need to know the endpoint for your Bluemix web service.  You can see the route that was created for your application using `cf routes`.  The running application URL can be determined by combining the host and domain from the routes listing.  You can also find this information in the `manifest.yml` file. By default the route should be `wex-ce.myBluemix.net`.  The route is also available from your application dashboard in Bluemix.

#### Running the provided command line tool

The provided Ruby-based command line tool called `get-expanded-concepts.rb` takes a list of terms, sends them to the Concept Expansion web service in Bluemix, and saves the returned list of concepts in a file as XML.

[Ruby is required to run this script](/README.md#required-development-tools-1).

```
$> ruby get-expanded-concepts.rb --help
Usage: get-expanded-concepts.rb -i input [options]
    -i, --in input                   Path to newline separated file that will be the input.
    -e, --endpoint endpoint          The base endpoint hosting the BlueMix web service, for example: http://wex-ce.mybluemix.net/
    -o, --out output                 Optional. Path to file where the results should be written.
    -l, --label label                Optional. Label applied to the concept set.
    -d, --dataset name               Optional. Name of the dataset to use. mtsamples or twitter
    -w, --wait seconds               Optional. Time in seconds that the service should delay between tries.
    -t, --tries count                Optional. Number of times the service should attempt to fetch results before giving up.

$> ruby get-expanded-concepts.rb --in=sample-input.txt --endpoint=http://wex-ce.mybluemix.net --label=Medications
```


Default values are provided for all optional arguments.


### Configuring the Watson Explorer Engine

The output of the command line tool is an XML file suitable for ingestion as a query expansion ontolection. There is [an excellent tutorial available in the Watson Explorer documentation](http://www-01.ibm.com/support/knowledgecenter/SS8NLW_9.0.0/com.ibm.swg.im.infosphere.dataexpl.engine.tut.cs.doc/c_csearch-ontolection-tut.html?lang=en) that describes how to crawl any files you create using the command line tool as an ontolection that can be used for query expansion or conceptual search. A custom ontolection collection [can be configured for use within Application Builder](http://www-01.ibm.com/support/knowledgecenter/SS8NLW_9.0.0/com.ibm.swg.im.infosphere.dataexpl.appbuilder.doc/t_de-ab-devapp-search-qe.html?lang=en).


### Production and Deployment Considerations

These examples are intended for demonstrative purposes only.  While you might be able to reuse the patterns and even parts of the code from these examples, there are several concerns that should be considered when developing a production-grade application.

- _Maintainability_ - For the example, only the Watson Concept Expansion Service is built into the Bluemix application. If this were a real application you should consider creating a single Bluemix application for all cloud based cognitive (or other) services used within Bluemix.
- _Security_ - The example Bluemix applications are completely open and have no security.
- _Scalability_ - This example uses only a single cloud instance with the default Bluemix application settings.  In a production scenario consider how much hardware will be required and adjust the Bluemix application settings accordingly.
- _Performance_ - The Concept Expansion service is designed as an offline analysis tool. Depending on the analysis you are doing, the service may require significant time to complete (on the order of minutes). Depending on where you intend to inject the integration you may need to employ other tactics to ensure the integration meets performance requirements.


## Possible Use Cases for a Watson Concept Expansion/Watson Explorer Integration

Watson Concept Expansion expands a list of terms by related concepts.  Within Watson Explorer it may be possible to use this information to enhance conceptual search use cases, for example, so users will still find relevant results even when specific query terms are not in the index.

* Expand metadata for documents as a means of tuning relevancy by allowing users to search across concepts that may not initially be present in a document.
* Create ontolections that can be used for conceptual search through query expansion.
* Develop additional keywords that can be used to improve spotlight trigger words. Use an initial set of trigger words as the input seed and then choose from the conceptual expansion what additional trigger words to add.
