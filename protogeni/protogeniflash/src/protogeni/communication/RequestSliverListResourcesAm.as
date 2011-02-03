﻿/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2008, 2009 University of Utah and the Flux Group.
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute this software is hereby
 * granted provided that (1) source code retains these copyright, permission,
 * and disclaimer notices, and (2) redistributions including binaries
 * reproduce the notices in supporting documentation.
 *
 * THE UNIVERSITY OF UTAH ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  THE UNIVERSITY OF UTAH DISCLAIMS ANY LIABILITY OF ANY KIND
 * FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 */

package protogeni.communication
{
  import com.mattism.http.xmlrpc.MethodFault;
  
  import flash.events.ErrorEvent;
  import flash.events.SecurityErrorEvent;
  import flash.utils.ByteArray;
  
  import mx.utils.Base64Decoder;
  
  import protogeni.Util;
  import protogeni.resources.AggregateManager;
  import protogeni.resources.ComponentManager;
  import protogeni.resources.GeniManager;
  import protogeni.resources.Sliver;

  public class RequestSliverListResourcesAm extends Request
  {
	  
    public function RequestSliverListResourcesAm(s:Sliver) : void
    {
		super("ListResources (" + Util.shortenString(s.manager.Url, 15) + ")", "Listing resources for sliver on " + s.manager.Hrn + " on slice named " + s.slice.hrn, CommunicationUtil.listResourcesAm, true);
		ignoreReturnCode = true;
		op.timeout = 60;
		sliver = s;
		op.pushField([sliver.slice.credential]);
		op.pushField({geni_available:false, geni_compressed:true, geni_slice_urn:sliver.slice.urn});	// geni_available:false = show all, true = show only available
		op.setUrl(sliver.manager.Url);
    }
	
	override public function complete(code : Number, response : Object) : *
	{
		try
		{
			var decodor:Base64Decoder = new Base64Decoder();
			decodor.decode(response as String);
			var bytes:ByteArray = decodor.toByteArray();
			bytes.uncompress();
			var decodedRspec:String = bytes.toString();
			sliver.rspec = new XML(decodedRspec);
			
			sliver.created = true;
			sliver.parseRspec();
			Main.geniHandler.dispatchSliceChanged(sliver.slice);
			return new RequestSliverStatusAm(sliver);
			
		} catch(e:Error)
		{
		}
		
		return null;
	}

    private var sliver:Sliver;
  }
}
