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
 
 package protogeni.resources
{	
	import mx.collections.ArrayCollection;
	
	// Group of physical nodes located in one area
	public class PhysicalNodeGroup
	{
		public var latitude:Number;
		public var longitude:Number;
		public var country:String;
		[Bindable]
		public var city:String = "";
		
		public var owner:PhysicalNodeGroupCollection = null;
		public var collection:ArrayCollection = new ArrayCollection;
		public var links:PhysicalLinkGroup = null;
		
		public function PhysicalNodeGroup(lat:Number = -1, lng:Number = -1, cnt:String = "", own:PhysicalNodeGroupCollection = null)
		{
			latitude = lat;
			longitude = lng;
			country = cnt;
			owner = own;
		}
		
		public function Add(n:PhysicalNode):void {
			collection.addItem(n);
		}

		public function GetByUrn(urn:String):PhysicalNode {
			for each ( var n:PhysicalNode in collection ) {
				if(n.urn == urn)
					return n;
			}
			return null;
		}
		
		public function GetByName(name:String):PhysicalNode {
			for each ( var n:PhysicalNode in collection ) {
				if(n.name == name)
					return n;
			}
			return null;
		}
		
		public function GetByType(type:String):PhysicalNodeGroup {
			var group:PhysicalNodeGroup = new PhysicalNodeGroup();
			for each ( var n:PhysicalNode in collection ) {
				for each ( var nt:NodeType in n.types ) {
					if(nt.name == type) {
						group.Add(n);
						break;
					}
				}
			}
			return group;
		}
		
		public function Available():Number {
			var cnt:Number = 0;
			for each ( var n:PhysicalNode in collection ) {
				if(n.available)
					cnt++;
			}
			return cnt;
		}
		
		public function ExternalLinks():Number {
			var cnt:Number = 0;
			for each ( var n:PhysicalNode in collection ) {
				for each ( var l:PhysicalLink in n.GetLinks() ) {
					if(l.owner != n.owner.links)
						cnt++;
				}
			}
			return cnt;
		}
	}
}