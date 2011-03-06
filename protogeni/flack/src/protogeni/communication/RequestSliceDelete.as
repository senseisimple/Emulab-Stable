﻿/* GENIPUBLIC-COPYRIGHT
* Copyright (c) 2008-2011 University of Utah and the Flux Group.
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
	import protogeni.resources.Slice;
	
	public final class RequestSliceDelete extends Request
	{
		private var slice:Slice;
		
		public function RequestSliceDelete(s:Slice):void
		{
			super("SliceDelete", "Deleting slice named " + s.hrn, CommunicationUtil.deleteSlice);
			slice = s;
			op.addField("slice_urn", slice.urn.full);
			op.addField("credential", Main.geniHandler.CurrentUser.credential);
			// What CM???
		}
		
		override public function complete(code:Number, response:Object):*
		{
			if (code == CommunicationUtil.GENIRESPONSE_SUCCESS
				|| code == CommunicationUtil.GENIRESPONSE_SEARCHFAILED)
			{
				//??
			}
			else
			{
				//??
			}
		}
	}
}
