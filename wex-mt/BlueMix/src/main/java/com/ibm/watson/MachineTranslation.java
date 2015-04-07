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



@javax.ws.rs.ApplicationPath("resources")
@Path("/translate")
public class MachineTranslation extends javax.ws.rs.core.Application
{

	@Context
	private UriInfo context;

	@POST
	@Consumes(MediaType.APPLICATION_FORM_URLENCODED)
	@Produces(MediaType.APPLICATION_JSON)
	public Response getTranslation(@FormParam("text") String text,
		                           @FormParam("from") String from_id,
		                           @FormParam("to") String to_id) throws Exception
	{
		String errorMessage = checkText(text, from_id, to_id);
		if (errorMessage != null)
		{
			return returnHTTPResponse(Response.Status.BAD_REQUEST, errorMessage);
		}

		// no errors in the input parameters, let's get down to business.

		try
		{
			MachineTranslationRequest request = new MachineTranslationRequest();
			String json = request.translateText(text, from_id, to_id);
			
			return returnHTTPResponse(Response.Status.ACCEPTED, json);
			
		}
		catch (Exception e)
		{
			System.out.println(e.getMessage());
			return returnHTTPResponse(Response.Status.BAD_REQUEST, "{\"error\": \" Watson service information was not found.  Is the Watson MT service associated with this application? \"}");
		}

	}


  private String checkText(String text, String fromId, String toId)
  {
  	if(text == null || text.isEmpty())
  	{
  		return "{\"error\": \" No words to evaluate! \"}";
	}

	if (fromId.equals(toId))
	{
		return "{\"error\": \" From and to ID should be different! (it's just a demo, cut me a break :) \"}";
	}

	return null;
  }



  private Response returnHTTPResponse( Response.Status status, String string)
  {
  	return Response.status(status)
  				   .header("Pragma", "no-cache")
			       .header("Cache-Control", "no-cache")
			       .entity(string)
			       .build();
  }


}
