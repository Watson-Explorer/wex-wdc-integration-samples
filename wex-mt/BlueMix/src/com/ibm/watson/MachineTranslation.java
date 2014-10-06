package com.ibm.watson;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;

import javax.ws.rs.Consumes;
import javax.ws.rs.FormParam;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.UriInfo;

import org.apache.commons.codec.binary.Base64;
import org.apache.wink.json4j.JSON;
import org.apache.wink.json4j.JSONArray;
import org.apache.wink.json4j.JSONException;
import org.apache.wink.json4j.JSONObject;

@javax.ws.rs.ApplicationPath("resources")
@Path("/translate")
public class MachineTranslation extends javax.ws.rs.core.Application {
	private static final String WIDGET_SEPERATOR = "#&#";
	

	@Context
	private UriInfo context;

	@POST
	@Consumes(MediaType.APPLICATION_FORM_URLENCODED)
	@Produces(MediaType.APPLICATION_JSON)

	public Response getTranslation(@FormParam("text") String text, @FormParam("sid") String sid)
			throws Exception {

		String username = null;
		String passwd = null;
		String restServerURL = null;

		// Find my service from VCAP_SERVICES in BlueMix
		String VCAP_SERVICES = System.getenv("VCAP_SERVICES");

		if (VCAP_SERVICES != null) {
			try {

				JSONObject credentials = getCredentials(VCAP_SERVICES);

				restServerURL = credentials.getString("uri");
				username = credentials.getString("userid");
				passwd = credentials.getString("password");
				JSONArray sids = credentials.getJSONArray("sids");

			} catch (NullPointerException | JSONException e) {

				// add logging
				e.printStackTrace();

			}
		} else {
			System.out
					.println("VCAP_SERVICES is null for the environment.  "
							+ "Services are probably not associated with this application.");
			return returnHTTPResponse( Response.Status.BAD_REQUEST, "{\"error\": \" Watson service information was not found.  Is the Watson MT service associated with this application? \"}");
		}

		try {
			if(text == null || text.isEmpty()){
				return returnHTTPResponse( Response.Status.BAD_REQUEST, "{\"error\": \" No words to evaluate! \"}");
			}
			
			String[] splitRequest = text.split(WIDGET_SEPERATOR);
			StringBuilder resultStringBuilder = new StringBuilder("[");
			JSONArray resultJson = new JSONArray();

			for (String singleText : splitRequest) {
				String postRequest = "seg=ppl&rt=text&sid=" + URLEncoder.encode(sid, "UTF-8")
						+ "&txt=" + URLEncoder.encode(singleText, "UTF-8") ;

				// prepare the HTTP connection
				HttpURLConnection httpURLConnection = (HttpURLConnection) new URL(restServerURL)
						.openConnection();

				setPropertiesOnConnection(httpURLConnection, username, passwd);

				DataOutputStream output = new DataOutputStream(
						httpURLConnection.getOutputStream());
				// make the connection
				httpURLConnection.connect();
				// post request
				output.writeBytes(postRequest);
				output.flush();
				output.close();

				// read response
				BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(
						httpURLConnection.getInputStream(), "UTF-8"));
				if (httpURLConnection.getResponseCode() == HttpURLConnection.HTTP_OK) {
				} else {
					System.err.println("Unsuccesful response: "
							+ httpURLConnection.getResponseCode() + " from: "
							+ httpURLConnection.getURL().toString());
				}
				
				String line = "";
				StringBuffer stringBuffer = new StringBuffer();
				while ((line = bufferedReader.readLine()) != null) {
					stringBuffer.append(line);
					stringBuffer.append("\n");
				}
				bufferedReader.close();
				
				JSONObject jsonResultObject = new JSONObject();
				jsonResultObject.put("result", stringBuffer.toString());
				resultJson.put(jsonResultObject);

			}
			return  returnHTTPResponse( Response.Status.ACCEPTED, resultJson.toString());

		} catch (MalformedURLException e) {
			e.printStackTrace();
			throw new RuntimeException("bad url " + restServerURL);
		} catch (Exception e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	private  JSONObject getCredentials (String VCAP_SERVICES ) {
		JSONObject credentials = null;
		try {
			JSONObject obj = (JSONObject) JSON.parse(VCAP_SERVICES);
			JSONArray service = obj.getJSONArray("smt");
			// retrieve the service information
			JSONObject catalog = service.getJSONObject(0);
			// retrieve the credentials
			credentials = catalog.getJSONObject("credentials");

		} catch (NullPointerException | JSONException e) {
				e.printStackTrace();
		} 

		return credentials;

	}

	private void setPropertiesOnConnection(HttpURLConnection httpURLConnection, String username, String passwd) throws Exception {

		httpURLConnection.setDoInput(true);
		httpURLConnection.setDoOutput(true);
		httpURLConnection.setUseCaches(false);
		httpURLConnection.setRequestMethod("POST");
		httpURLConnection.setRequestProperty("Accept", "*/*");
		httpURLConnection.setRequestProperty("Connection", "Keep-Alive");
		httpURLConnection.setRequestProperty("Content-Type","application/x-www-form-urlencoded");
		String auth = username + ":" + passwd;
		httpURLConnection.setRequestProperty("Authorization","Basic " + Base64.encodeBase64String(auth.getBytes()));
	}


   private Response returnHTTPResponse( Response.Status status, String string) {
   	return Response
			.status(status)
			.header("Pragma", "no-cache")
			.header("Cache-Control", "no-cache")
			.entity(string)
			.build();
   }


}
