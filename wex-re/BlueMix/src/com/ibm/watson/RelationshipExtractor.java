package com.ibm.watson;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.FormParam;

import org.apache.wink.json4j.JSONException;
import org.apache.wink.json4j.JSONObject;

import org.apache.commons.codec.binary.Base64;

import java.io.*;
import java.net.URL;
import java.net.URLEncoder;
import java.net.URLConnection;
import java.net.HttpURLConnection;


@Path("/extract")
public class RelationshipExtractor {
    
    @GET
    public String getInformation() throws JSONException {
	
	// 'VCAP_APPLICATION' is in JSON format, it contains useful information about a deployed application
	// String envApp = System.getenv("VCAP_APPLICATION");
	
	// 'VCAP_SERVICES' contains all the credentials of services bound to this application.
	// String envServices = System.getenv("VCAP_SERVICES");
	
	// load all system environments
	JSONObject sysEnv = new JSONObject(System.getenv());
	if(sysEnv.containsKey("VCAP_SERVICES"))
	    sysEnv.put("VCAP_SERVICES", "**hidden**"); //We don't want to show this information on the web page.
	sysEnv.put("check", "one two three");
	return sysEnv.toString();
	
    }
    
    @POST
    public String extract(@FormParam("sid") String sid,
                             @FormParam("text") String text)  {

	if (text==null || "".equals(text)) return ""; //Nothing to do if there is no text
        String username = "xxx";
        String passwd = "xxx";
        String post = "xxx";
	
        try {
	    //Get the service endpoint details
            JSONObject serviceInfo = new JSONObject(System.getenv("VCAP_SERVICES"));
            JSONObject credentials = serviceInfo.getJSONArray("sire").getJSONObject(0).getJSONObject("credentials");
            String restServerURL = credentials.getString("uri");
            username = credentials.getString("userid");
            passwd = credentials.getString("password");

	    //Construct the payload that we will send to the service	    
	    if (sid==null) {
		// default to English news if no sid provided
		post = "sid=ie-en-news" +
		    "&txt=" + URLEncoder.encode(text, "UTF-8");
	    } else {
		post = "sid=" + URLEncoder.encode(sid, "UTF-8") +
		    "&txt=" + URLEncoder.encode(text, "UTF-8");
	    }        

            //Prepare the HTTP connection to the service
            HttpURLConnection conn = (HttpURLConnection)new URL(restServerURL).openConnection();
            conn.setDoInput(true);
            conn.setDoOutput(true);
            conn.setUseCaches(false);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Accept", "*/*");
            conn.setRequestProperty("Connection", "Keep-Alive");
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            String auth = username + ":" + passwd;
            conn.setRequestProperty("Authorization", "Basic "+Base64.encodeBase64String(auth.getBytes()));
            DataOutputStream output = new DataOutputStream(conn.getOutputStream());
            // make the connection
            conn.connect();
            // post request
            output.writeBytes(post);
            output.flush();
            output.close();

            //Read the response from the service
            BufferedReader rdr = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            /*
              if (conn.getResponseCode()==HttpURLConnection.HTTP_OK)
              System.out.println("Response OK  from: "+conn.getURL().toString());
              else
              System.err.println("Unsuccesful response: "+conn.getResponseCode()+ " from: "+conn.getURL().toString());
            */
            String line = "";
            StringBuffer buf = new StringBuffer();
            while ((line = rdr.readLine()) != null) {
                buf.append(line);
                buf.append("\n");
            }
            rdr.close();

	    //Return the response from the service
            return buf.toString();

        } catch (Exception e) {
	    //Returning any non-200 HTTP status code from the service might facilitate better error handling...
            return "used u:"+username
                +"\np:"+passwd
                +"\npost:"+post
                +"\n"+e.toString();
        }

    }
}
