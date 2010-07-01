package pgmap
{
	import com.google.maps.InfoWindowOptions;
	import com.google.maps.LatLng;
	import com.google.maps.LatLngBounds;
	import com.google.maps.MapMouseEvent;
	import com.google.maps.overlays.Marker;
	import com.google.maps.overlays.MarkerOptions;
	import com.google.maps.overlays.Polyline;
	import com.google.maps.overlays.PolylineOptions;
	import com.google.maps.services.ClientGeocoder;
	import com.google.maps.services.GeocodingEvent;
	import com.google.maps.services.Placemark;
	import com.google.maps.styles.FillStyle;
	import com.google.maps.styles.StrokeStyle;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.events.FlexEvent;
	
    // Handles adding all the ProtoGENI info to the Google Map component
	public class ProtoGeniMapHandler
	{
		public var main : pgmap;
		
		public function ProtoGeniMapHandler()
		{
		}
		
		private var markers:ArrayCollection;
		private var clusterMarkers:ArrayCollection;
		private var linkLineOverlays:ArrayCollection;
		private var linkLabelOverlays:ArrayCollection;

		private var nodeGroupClusters:ArrayCollection;		
		
		private function addNodeGroupMarker(g:PhysicalNodeGroup):void
	    {
	    	// Create the group to be drawn
	    	var drawGroup:PhysicalNodeGroup = new PhysicalNodeGroup(g.latitude, g.longitude, g.country, g.owner);
	    	if(main.userResourcesOnly) {
	    		for each(var n:PhysicalNode in g.collection) {
	    			for each(var vn:VirtualNode in n.virtualNodes)
	    			{
	    				if(vn.sliver.slice == main.selectedSlice)
	    				{
	    					drawGroup.Add(n);
	    					break;
	    				}
	    			}
	    		}
	    	} else {
	    		drawGroup = g;
	    	}
	    	
	    	if(drawGroup.collection.length > 0) {
	    		var m:Marker = new Marker(
			      	new LatLng(g.latitude, g.longitude),
			      	new MarkerOptions({
			                  strokeStyle: new StrokeStyle({color: 0x092B9F}),
			                  fillStyle: new FillStyle({color: 0xD2E1F0, alpha: 1}),
			                  radius: 14,
			                  hasShadow: true,
			                  //tooltip: g.country,
			                  label: drawGroup.collection.length.toString()
			      	}));
	
		        var groupInfo:PhysicalNodeGroupInfo = new PhysicalNodeGroupInfo();
		        groupInfo.Load(drawGroup, main);
		        
		        if(g.city.length == 0)
		        {
			        var geocoder:ClientGeocoder = new ClientGeocoder();
			    	geocoder.addEventListener(GeocodingEvent.GEOCODING_SUCCESS,
					      function(event:GeocodingEvent):void {
					      	var placemarks:Array = event.response.placemarks;
					        if (placemarks.length > 0) {
					        	try {
					        		var p:Placemark = event.response.placemarks[0] as Placemark;
					        		var fullAddress : String = p.address;
					        		var splitAddress : Array = fullAddress.split(',');
					        		if(splitAddress.length == 3)
					        			groupInfo.city = splitAddress[0];
					        		else 
					        		if(splitAddress.length == 4)
					        			groupInfo.city = splitAddress[1];
					        		else
					        			groupInfo.city = fullAddress;
					        		g.city = groupInfo.city;
					        	} catch (err:Error) { }
					        }
					      });
					        	
					  geocoder.addEventListener(GeocodingEvent.GEOCODING_FAILURE,
					        function(event:GeocodingEvent):void {
								main.console.appendMessage(
									new LogMessage("","Geocoding failed (" + event.status + " / " + event.eventPhase + ")","",true));
					        });
		
					  geocoder.reverseGeocode(new LatLng(g.latitude, g.longitude));
		        } else {
		        	groupInfo.city = g.city;
		        }
		        m.addEventListener(MapMouseEvent.CLICK, function(e:Event):void {
		            m.openInfoWindow(
		            	new InfoWindowOptions({
		            		customContent:groupInfo,
		            		customoffset: new Point(0, 10),
		            		width:125,
		            		height:160,
		            		drawDefaultFrame:true
		            	}));
		        });
	
		  		main.map.addOverlay(m);
		  		markers.addItem({marker:m, nodeGroup:drawGroup});
	    	} else {
	    		// Draw an empty marker
	    		var nonodes:Marker = new Marker(
			      	new LatLng(g.latitude, g.longitude),
			      	new MarkerOptions({
			                  strokeStyle: new StrokeStyle({color: 0x666666}),
			                  fillStyle: new FillStyle({color: 0xCCCCCC, alpha: .8}),
			                  radius: 8,
			                  hasShadow: false
			      	}));
	
		        main.map.addOverlay(nonodes);
	    	}
	        
	    }
	    
	    private function addNodeGroupCluster(nodeGroups:ArrayCollection):void {
	    	var totalNodes:Number = 0;
	    	var l:LatLngBounds = new LatLngBounds();
	    	var upperLat:Number = nodeGroups[0].nodeGroup.latitude;
	    	var lowerLat:Number = nodeGroups[0].nodeGroup.latitude;
	    	var rightLong:Number = nodeGroups[0].nodeGroup.longitude;
	    	var leftLong:Number = nodeGroups[0].nodeGroup.longitude;
	    	var nodeGroupsOnly:ArrayCollection = new ArrayCollection();
	    	for each(var o:Object in nodeGroups) {
	    		// Check to see if the new group expends the cluster size
	    		if(o.nodeGroup.latitude > upperLat)
	    			upperLat = o.nodeGroup.latitude;
	    		else if(o.nodeGroup.latitude < lowerLat)
	    			lowerLat = o.nodeGroup.latitude;
	    		if(o.nodeGroup.longitude > rightLong)
	    			rightLong = o.nodeGroup.longitude;
	    		else if(o.nodeGroup.longitude < leftLong)
	    			leftLong = o.nodeGroup.longitude;

	    		totalNodes += o.nodeGroup.collection.length;
	    		nodeGroupsOnly.addItem(o.nodeGroup);
	    		o.marker.visible = false;
	    	}
	    	
	    	// Save the bounds of the cluster
	    	var bounds:LatLngBounds = new LatLngBounds(new LatLng(upperLat, leftLong), new LatLng(lowerLat, rightLong));
	    	
	    	var clusterInfo:PhysicalNodeGroupClusterInfo = new PhysicalNodeGroupClusterInfo();
	    	clusterInfo.addEventListener(FlexEvent.CREATION_COMPLETE,
	    		function loadNodeGroup(evt:FlexEvent):void {
	    			clusterInfo.Load(nodeGroupsOnly);
		    		clusterInfo.setZoomButton(bounds);
	    		});
		    

	    	var m:Marker = new Marker(
		      	bounds.getCenter(),
		      	new MarkerOptions({
		      			  icon:new iconLabelSprite(totalNodes.toString()),
		      			  //iconAllignment:MarkerOptions.ALIGN_RIGHT,
		      			  iconOffset:new Point(-20, -20),
		                  hasShadow: true
		      	}));
		    
		    m.addEventListener(MapMouseEvent.CLICK, function(e:Event):void {
					m.openInfoWindow(
		            	new InfoWindowOptions({
		            		customContent:clusterInfo,
		            		customoffset: new Point(0, 10),
		            		width:180,
		            		height:170,
		            		drawDefaultFrame:true
		            	}));
		        });


	  		main.map.addOverlay(m);
	  		clusterMarkers.addItem(m);
	    }
	    
	    public function addPhysicalLink(lg:PhysicalLinkGroup):void {
	    	// Create the group to be drawn
	    	var drawGroup:PhysicalLinkGroup = lg;
			for each(var v:PhysicalLink in drawGroup.collection)
			{
				if(v.rspec.toXMLString().indexOf("ipv4") > -1)
				{
					main.console.appendText("Skipped");
					return;
				}
			}
	    	
	    	if(drawGroup.collection.length > 0 && !main.userResourcesOnly) {
	    		// Add line
				var polyline:Polyline = new Polyline([
					new LatLng(drawGroup.latitude1, drawGroup.longitude1),
					new LatLng(drawGroup.latitude2, drawGroup.longitude2)
					], new PolylineOptions({ strokeStyle: new StrokeStyle({
						color: Common.linkBorderColor,
						thickness: 4,
						alpha:1})
					}));
	
				main.map.addOverlay(polyline);
				linkLineOverlays.addItem(polyline);
				
				// Add link marker
				var ll:LatLng = new LatLng((drawGroup.latitude1 + drawGroup.latitude2)/2, (drawGroup.longitude1 + drawGroup.longitude2)/2);
				
				var t:TooltipOverlay = new TooltipOverlay(ll, Common.kbsToString(drawGroup.TotalBandwidth()), Common.linkBorderColor, Common.linkColor);
		  		t.addEventListener(MouseEvent.CLICK, function(e:Event):void {
		            e.stopImmediatePropagation();
		            Common.viewPhysicalLinkGroup(drawGroup)
		        });
		        
		  		main.map.addOverlay(t);
				linkLabelOverlays.addItem(t);
	    	} else {
	    		// Add line
				var blankline:Polyline = new Polyline([
					new LatLng(drawGroup.latitude1, drawGroup.longitude1),
					new LatLng(drawGroup.latitude2, drawGroup.longitude2)
					], new PolylineOptions({ strokeStyle: new StrokeStyle({
						color: 0x666666,
						thickness: 3,
						alpha:.8})
					}));

				main.map.addOverlay(blankline);
	    	}
	    }
	    
	    public function addVirtualLink(pl:VirtualLink):void {
    		// Add line
    		var backColor:Object = Common.linkColor;
    		var borderColor:Object = Common.linkBorderColor;
    		if(pl.type == "tunnel")
    		{
    			backColor = Common.tunnelColor;
    			borderColor = Common.tunnelBorderColor;
    		}
    		
    		var current:int = 0;
    		var node1:PhysicalNode = (pl.interfaces[pl.interfaces.length - 1] as VirtualInterface).virtualNode.physicalNode;
    		while(current != pl.interfaces.length - 1)
    		{
    			var node2:PhysicalNode = (pl.interfaces[current] as VirtualInterface).virtualNode.physicalNode;
    			
				if(node1.owner == node2.owner)
				{
					node1 = node2;
					current++;
					if(current == pl.interfaces.length)
    				current = 0;
					continue;
				}
					
    			var firstll:LatLng = new LatLng(node1.GetLatitude(), node1.GetLongitude());
	    		var secondll:LatLng = new LatLng(node2.GetLatitude(), node2.GetLongitude());
				
				var polyline:Polyline = new Polyline([
					firstll,
					secondll
					], new PolylineOptions({ strokeStyle: new StrokeStyle({
						color: borderColor,
						thickness: 4,
						alpha:1})
					}));
	
				main.map.addOverlay(polyline);
				linkLineOverlays.addItem(polyline);
					
				// Add point link marker
				var ll:LatLng = new LatLng((firstll.lat() + secondll.lat())/2, (firstll.lng() + secondll.lng())/2);
				
				var t:TooltipOverlay = new TooltipOverlay(ll, Common.kbsToString(pl.bandwidth), borderColor, backColor);
		  		t.addEventListener(MouseEvent.CLICK, function(e:Event):void {
		            e.stopImmediatePropagation();
		            Common.viewVirtualLink(pl)
		        });
		        
		  		main.map.addOverlay(t);
				linkLabelOverlays.addItem(t);
				
				node1 = node2;
				current++;
				if(current == pl.interfaces.length)
    				current = 0;
    		}
	    }
	    
	    public function drawAll():void {
	    	drawMap();
	    	main.fillCombobox();
	    }
	    
	    public function drawMap():void {
	    	main.setProgress("Drawing map",Common.waitColor);
	    	
	    	main.map.closeInfoWindow();
	    	main.map.clearOverlays();

	    	linkLabelOverlays = new ArrayCollection();
	    	linkLineOverlays = new ArrayCollection();
	        markers = new ArrayCollection();
	    	
	    	// Draw physical components
	    	for each(var cm:ComponentManager in main.pgHandler.ComponentManagers)
	    	{
	    		if(!cm.Show)
	    			continue;
	    		
	    		// Links
		        for each(var l:PhysicalLinkGroup in cm.Links.collection) {
			        	if(!l.IsSameSite()) {
			        		addPhysicalLink(l);
			        	}
			       }
		        
		        // Nodes
		    	for each(var g:PhysicalNodeGroup in cm.Nodes.collection) {
		        	addNodeGroupMarker(g);
		        }
	    	}
	    	
	    	if(main.userResourcesOnly && main.selectedSlice != null && main.selectedSlice.Status() != null) {
	    		// Draw virtual links
	    		for each(var sliver:Sliver in main.selectedSlice.slivers)
	    		{
	    			if(!sliver.componentManager.Show)
	    				continue;
	    			for each(var vl:VirtualLink in sliver.links) {
			        	addVirtualLink(vl);
			        }	    			
	    		}
	        }
	    	
	    	// Combine overlapping markers
	        clusterMarkers = new ArrayCollection();
	        nodeGroupClusters = new ArrayCollection();
	        var added:ArrayCollection = new ArrayCollection();
	        for each(var o:Object in markers) {
	        	if(!added.contains(o)) {
	        		var overlapping:ArrayCollection = new ArrayCollection();
		        	getOverlapping(o, overlapping);
		        	if(overlapping.length > 0) {
		        		added.addAll(overlapping);
		        		nodeGroupClusters.addItem(overlapping);
		        		addNodeGroupCluster(overlapping);
		        	}
	        	}
	        }
	        
	        // Remove link items that are blocking markers
	        for each(var linkLabel:TooltipOverlay in linkLabelOverlays)
	        {
	        	var removed:Boolean = false;
	        	 var d:DisplayObject = linkLabel.foreground;
	        	for each(var clusterMarker:Marker in clusterMarkers) {
	        		if(linkLabel.foreground.hitTestObject(clusterMarker.foreground)) {
	        			main.map.removeOverlay(linkLabel);
	        			removed = true;
	        			break;
	        		}
		        }
		        if(!removed)
		        {
		        	for each(var ngo:Object in markers) {
		        		var nodegroupMarker:Marker = ngo.marker;
		        		if(linkLabel.foreground.hitTestObject(nodegroupMarker.foreground)) {
		        			main.map.removeOverlay(linkLabel);
		        			break;
		        		}
			        }
		        }
	        }

	        main.setProgress("Done", Common.successColor);
	    }
	    
	    public function getOverlapping(o:Object, added:ArrayCollection):void {
	    	var m:Marker = o.marker;
	        var d:DisplayObject = m.foreground;
        	for each(var o2:Object in markers) {
        		if(o2 != o && !added.contains(o2)) {
		        	var m2:Marker = o2.marker;
		        	var d2:DisplayObject = m2.foreground;
	        		if(d.hitTestObject(d2)) {
	        			added.addItem(o2);
	        			getOverlapping(o2, added);
	        		}
        		}
	        }
	    }
	}
}