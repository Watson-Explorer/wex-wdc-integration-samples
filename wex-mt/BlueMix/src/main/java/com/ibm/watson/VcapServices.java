package com.ibm.watson;

import org.apache.wink.json4j.JSON;
import org.apache.wink.json4j.JSONArray;
import org.apache.wink.json4j.JSONObject;

public class VcapServices
{
	private String _serviceUrl;
	private String _username;
	private String _password;

	
	public VcapServices()
	{
		
	}
	

	public String getPassword() { return _password; }
	public String getUsername() { return _username; }
	public String getUrl() { return _serviceUrl; }
	
	
	public void getCredentialsFor(String serviceName) throws Exception
	{
		String vcap_environment = System.getenv("VCAP_SERVICES");
				
		if (vcap_environment != null)
		{
		
			JSONObject credentials = getCredentials(vcap_environment, serviceName);
			
			this._serviceUrl = credentials.getString("url");
			this._username = credentials.getString("username");
			this._password = credentials.getString("password");
	//		JSONArray sids = credentials.getJSONArray("sids");
		}
		else
		{
			throw new Exception("VCAP_SERVICES is null for the environment. Services are probably not associated with this application.");
		}
	}
	

	
	private JSONObject getCredentials (String vcapServices, String serviceName) throws Exception
	{
		JSONObject credentials = null;
		try
		{
			JSONObject obj = (JSONObject) JSON.parse(vcapServices);
			JSONArray service = obj.getJSONArray(serviceName);
			// retrieve the service information
			JSONObject catalog = service.getJSONObject(0);
			// retrieve the credentials
			credentials = catalog.getJSONObject("credentials");

		}
		catch (Exception e)
		{
				throw new Exception(e);
		} 

		return credentials;

	}

}
