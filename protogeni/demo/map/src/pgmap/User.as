/* GENIPUBLIC-COPYRIGHT
 * Copyright (c) 2009 University of Utah and the Flux Group.
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
 
 package pgmap
{
	import mx.collections.ArrayCollection;
	
	public class User
	{
		public var uid : String;
		public var uuid : String = "66f3b32e-9666-11de-9be3-001143e453fe";
		public var hrn : String;
		public var email : String;
		public var name : String;
		public var credential : String;
		
		public var slices:ArrayCollection = new ArrayCollection();
		
		public function User()
		{
		}
		
		public function displaySlices():ArrayCollection {
			var ac : ArrayCollection = new ArrayCollection();
			ac.addItem(new Slice());
			for each(var s:Slice in slices) {
				ac.addItem(s);
			}
			return ac;
		}
	}
}