package com.ibm.watson;

import javax.ws.rs.Consumes;
import javax.ws.rs.FormParam;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLContextBuilder;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.wink.json4j.JSON;
import org.apache.wink.json4j.JSONArray;
import org.apache.wink.json4j.JSONArtifact;
import org.apache.wink.json4j.JSONException;
import org.apache.wink.json4j.JSONObject;

@javax.ws.rs.ApplicationPath("resources")
@Path("/resonate")
public class MessageResonance extends javax.ws.rs.core.Application
{
	@Context
	private UriInfo context;

	@POST
	@Consumes(MediaType.APPLICATION_FORM_URLENCODED)
	@Produces(MediaType.APPLICATION_JSON)
	public Response getMessageResonance(@FormParam("message") String message) throws Exception
	{

		String userid = null;
		String password = null;
		String endpointBaseURI = null;
		String ringScoreURI = null;
		String datasetURI = null;

		// Find my service from VCAP_SERVICES in Bluemix
		String VCAP_SERVICES = System.getenv("VCAP_SERVICES");
		String Service_Name = "message_resonance";

		// Get the Service Credentials for Watson Message Resonance
		if (VCAP_SERVICES != null && ((JSONObject) JSON.parse(VCAP_SERVICES)).containsKey(Service_Name))
		{
			try
			{
				JSONObject obj = (JSONObject) JSON.parse(VCAP_SERVICES);
				JSONArray service = obj.getJSONArray(Service_Name);

				// retrieve the service information
				JSONObject catalog = service.getJSONObject(0);

				// retrieve the credentials
				JSONObject credentials = catalog.getJSONObject("credentials");

				// get the credential contents
				userid = credentials.getString("username");
				password = credentials.getString("password");
				endpointBaseURI = credentials.getString("url");
				JSONArray services = credentials.getJSONArray("services");
				JSONObject ringObject = services.getJSONObject(0);
				ringScoreURI = endpointBaseURI + "/" + ringObject.getJSONObject("ringscore").getString("path");
				datasetURI = endpointBaseURI + "/" + ringObject.getJSONObject("datasets").getString("path");

			}

			catch (Exception e)
			{
				e.printStackTrace();
			}
		}
		else
		{
			// add logging
			System.out.println("VCAP_SERVICES does not contain the Watson Service. Services are probably not associated with this application.");
			// generic error condition
			return Response.status(Response.Status.BAD_REQUEST)
										 .header("Pragma", "no-cache")
										 .header("Cache-Control", "no-cache")
										 .entity("{\"error\" : \"Watson service information was not found. Is the Watson Message Resonance service associated with this application?\"}")
										 .build();
		}

		// create credential information for security this contains the
		// information returned by the service
		CredentialsProvider provider = new BasicCredentialsProvider();
		UsernamePasswordCredentials credentials = new UsernamePasswordCredentials(userid, password);
		provider.setCredentials(AuthScope.ANY, credentials);

		// assume a self signed certificate which doesn't have a host name that
		// matches
		// Fix on service deployment
		SSLContextBuilder builder = new SSLContextBuilder();
		builder.loadTrustMaterial(null, new TrustSelfSignedStrategy());
		SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(builder.build(),
																																			SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
		CloseableHttpClient client = HttpClients.custom()
																						.setSSLSocketFactory(sslsf)
																					 	.setDefaultCredentialsProvider(provider).build();

		StringBuilder resultString = new StringBuilder();

		if (message == null || message.isEmpty())
		{
			resultString.append("{\"error\": \"No words to evaluate!\"}");
		}
		else
		{
			// Split the string on blocks of non-alphanumeric (by unicode standards) characters
			String[] words = message.split("(?U)\\W+");
		
			resultString.append("{\"results\":[");

			for (String word : words) {
				// create the HTTP Get operation
				HttpGet httpGet = new HttpGet(ringScoreURI + "?dataset=1&text=" + java.net.URLEncoder.encode(word, "UTF-8"));

				HttpResponse response = client.execute(httpGet);

				String serviceResponseString = EntityUtils.toString(response.getEntity());
				System.out.println("This is the return string: " + serviceResponseString);

				JSONObject serviceResponseJson = new JSONObject(serviceResponseString);
				boolean haveError = serviceResponseJson.containsKey("error") || !serviceResponseJson.containsKey("overall");
				if (haveError)
				{
					System.out.println("Error detected in service response ----------------  " );
					System.out.println(serviceResponseString);
					resultString = new StringBuilder("{\"error\": \"Service Error on " + word + "\"}");
				
					return Response.status(Response.Status.ACCEPTED)
												 .header("Pragma", "no-cache")
												 .header("Cache-Control", "no-cache")
												 .entity(resultString.toString()).build();
				}
				else
				{
					int score = (Integer) serviceResponseJson.get("overall");
					String calculateColorCode = calculateColorCode(score);
					resultString.append("{");
					resultString.append("\"word\":\"" + word + "\",");
					resultString.append("\"score\":\"" + score + "\",");
					resultString.append("\"color\":\"" + calculateColorCode + "\"");
					resultString.append("},");
				}

			}
			if (resultString.lastIndexOf(",") > 0)
			{
				resultString.deleteCharAt(resultString.lastIndexOf(","));
			}

			resultString.append("]}");
		}

		// return the response
		return Response.status(Response.Status.ACCEPTED)
									 .header("Pragma", "no-cache")
									 .header("Cache-Control", "no-cache")
   								 .entity(resultString.toString()).build();
	}

	private String calculateColorCode(int score)
	{
		if (score < 11)
			return "black";
		else if (score < 21)
			return "cornflowerblue";
		else if (score < 31)
			return "lawngreen";
		else if (score < 41)
			return "goldenrod";
		else
			return "crimson";
	}

}