package com.ibm.watson;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

import org.apache.commons.codec.binary.Base64;
import org.apache.wink.json4j.JSONArray;
import org.apache.wink.json4j.JSONException;
import org.apache.wink.json4j.JSONObject;

public class MachineTranslationRequest
{
	
	private static final String WIDGET_SEPERATOR = "#&#";
	
	
	
	public String translateText(String text, String fromId, String toId) throws JSONException, IOException, Exception
	{
		String[] splitRequest = text.split(WIDGET_SEPERATOR);
//		StringBuilder resultStringBuilder = new StringBuilder("[");

		String translationId = createTranslationId(fromId, toId);
		
		JSONArray json = new JSONArray();
		for (String singleText : splitRequest)
		{
			HttpURLConnection connection = createConnection();
			
    		String params = "seg=ppl&rt=text&sid=" + URLEncoder.encode(translationId, "UTF-8") + "&txt=" + URLEncoder.encode(singleText, "UTF-8");
    		
			// prepare the HTTP connection
    		JSONObject result = postRequest(connection, params);
    		json.put(result);
		}

		return  json.toString();
	}
	
	
	
	
	private String createTranslationId(String fromId, String toId)
	{
		return "mt-" + fromId + "-" + toId;
	}



	private HttpURLConnection createConnection() throws Exception
	{
			VcapServices vcap = new VcapServices();
			vcap.getCredentialsFor("machine_translation");
			
			// prepare the HTTP connection
			HttpURLConnection httpConnection = (HttpURLConnection) new URL(vcap.getUrl() + "/v1/smt/0").openConnection();
			setPropertiesOnConnection(httpConnection, vcap.getUsername(), vcap.getPassword());
			
			return httpConnection;
	}
	
	
	
	
	
	private JSONObject postRequest(HttpURLConnection connection, String params) throws IOException, JSONException
	{
		DataOutputStream output = new DataOutputStream(connection.getOutputStream());
				
		// make the connection
		connection.connect();
				
		// post request
		output.writeBytes(params);
		output.flush();
		output.close();

		// read response
		BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
		if (connection.getResponseCode() != HttpURLConnection.HTTP_OK)
		{
			System.err.println("Unsuccesful response: " + connection.getResponseCode() + " from: " + connection.getURL().toString());
		}

		return parseResult(bufferedReader);
	}
	
	
	private void setPropertiesOnConnection(HttpURLConnection httpURLConnection, String username, String passwd) throws Exception
	{
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
	
	
	
	private JSONObject parseResult(BufferedReader reader) throws IOException, JSONException
	{
		String line = "";
		StringBuffer stringBuffer = new StringBuffer();
		while ((line = reader.readLine()) != null)
		{
			stringBuffer.append(line);
			stringBuffer.append("\n");
		}

		reader.close();
		
		JSONObject json = new JSONObject();
		json.put("result", stringBuffer.toString());
		
		return json; 
	}
	
	
	


	
	
	

}
