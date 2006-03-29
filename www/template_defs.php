<?php
#
# EMULAB-COPYRIGHT
# Copyright (c) 2006 University of Utah and the Flux Group.
# All rights reserved.
#

#
# Grab a new GUID.
#
function TBNewGUID(&$newguid)
{
    DBQueryFatal("lock tables emulab_indicies write");

    $query_result = 
	DBQueryFatal("select idx from emulab_indicies ".
		     "where name='next_guid'");

    $row = mysql_fetch_array($query_result);
    $newguid = $row['idx'];
    $nextidx = $newguid + 1;
    
    DBQueryFatal("update emulab_indicies set idx='$nextidx' ".
		 "where name='next_guid'");

    DBQueryFatal("unlock tables");
    return 0;
}

#
# Confirm a valid experiment template
#
# usage TBValidExperimentTemplate($guid, $version)
#       returns 1 if valid
#       returns 0 if not valid
#
function TBValidExperimentTemplate($guid, $version)
{
    $guid    = addslashes($guid);
    $version = addslashes($version);

    $query_result =
	DBQueryFatal("select guid from experiment_templates ".
		     "where guid='$guid' and vers='$version'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    return 1;
}

#
# Experiment Template permission checks; using the experiment access checks.
#
# Usage: TBExptTemplateAccessCheck($uid, $guid, $access_type)
#	 returns 0 if not allowed.
#        returns 1 if allowed.
# 
function TBExptTemplateAccessCheck($uid, $guid, $access_type)
{
    global $TB_EXPT_READINFO;
    global $TB_EXPT_MODIFY;
    global $TB_EXPT_DESTROY;
    global $TB_EXPT_UPDATE;
    global $TB_EXPT_MIN;
    global $TB_EXPT_MAX;
    global $TBDB_TRUST_USER;
    global $TBDB_TRUST_LOCALROOT;
    global $TBDB_TRUST_GROUPROOT;
    global $TBDB_TRUST_PROJROOT;
    $mintrust;

    if ($access_type < $TB_EXPT_MIN ||
	$access_type > $TB_EXPT_MAX) {
	TBERROR("Invalid access type: $access_type!", 1);
    }

    #
    # Admins do whatever they want!
    # 
    if (ISADMIN()) {
	return 1;
    }
    $guid = addslashes($guid);

    $query_result =
	DBQueryFatal("select pid,gid,uid from experiment_templates where ".
		     "guid='$guid' limit 1");
    
    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row  = mysql_fetch_array($query_result);
    $pid  = $row[pid];
    $gid  = $row[gid];
    $head = $row[uid];

    if ($access_type == $TB_EXPT_READINFO) {
	$mintrust = $TBDB_TRUST_USER;
    }
    else {
	$mintrust = $TBDB_TRUST_LOCALROOT;
    }

    #
    # Either proper permission in the group, or group_root in the project.
    # This lets group_roots muck with other peoples experiments, including
    # those in groups they do not belong to.
    #
    return TBMinTrust(TBGrpTrust($uid, $pid, $gid), $mintrust) ||
	TBMinTrust(TBGrpTrust($uid, $pid, $pid), $TBDB_TRUST_GROUPROOT);
}

# Helper function
function ShowItem($tag, $value, $default = "&nbsp")
{
    if (!isset($value)) {
	$value = $default;
    }
    echo "<tr><td>${tag}: </td><td class=left>$value</td></tr>\n";
}

function MakeLink($which, $args, $text)
{
    $page = "";
    
    if ($which == "project") {
	$page = "showproject.php3";
    }
    elseif ($which == "user") {
	$page = "showuser.php3";
    }
    elseif ($which == "template") {
	$page = "template_show.php";
    }
    elseif ($which == "metadata") {
	$page = "template_metadata.php";
    }
    return "<a href=${page}?${args}>$text</a>";
}

#
# Display a template in its own table.
#
function SHOWTEMPLATE($guid, $version)
{
    $query_result =
	DBQueryFatal("select * from experiment_templates ".
		     "where guid='$guid' and vers='$version'");

    if (!mysql_num_rows($query_result)) {
	USERERROR("Experiment Template $guid/$version is no longer a ".
		  "valid template!", 1);
    }

    $row = mysql_fetch_array($query_result);

    #
    # Generate the table.
    #
    echo "<table align=center cellpadding=2 cellspacing=2 border=1>\n";
    
    ShowItem("GUID",
	     MakeLink("template",
		      "guid=$guid&version=$version", "$guid/$version"));
    ShowItem("ID",          $row['tid']);
    ShowItem("Project",
	     MakeLink("project", "pid=" . $row['pid'], $row['pid']));
    ShowItem("Group",       $row['gid']);
    ShowItem("Creator",
	     MakeLink("user", "target_uid=" . $row['uid'], $row['uid']));
    ShowItem("Created",     $row['created']);
    ShowItem("Modified",    $row['modified']);
    ShowItem("Description", $row['description']);
    if (isset($row['parent_guid'])) {
	$parent_guid = $row['parent_guid'];
	$parent_vers = $row['parent_vers'];
	ShowItem("Parent Template",
		 MakeLink("template",
			  "guid=$parent_guid&version=$parent_vers",
			  "$parent_guid/$parent_vers"));
    }
    echo "</table>\n";
}

#
# Display template parameters and default values in a table
#
function SHOWTEMPLATEPARAMETERS($guid, $version)
{
    if (!TBTemplatePidEid($guid, $version, &$pid, &$eid))
	return;
    
    $query_result =
	DBQueryFatal("select * from virt_parameters ".
		     "where pid='$pid' and eid='$eid'");

    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Template Parameters</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

 	echo "<tr>
                <th>Name</th>
                <th>Default Value</th>
              </tr>\n";

	while ($row = mysql_fetch_array($query_result)) {
	    $name	= $row['name'];
	    $value	= $row['value'];
	    if (!isset($value)) {
		$value = "&nbsp";
	    }

	    echo "<tr>
                   <td>$name</td>
                   <td>$value</td>
                  </tr>\n";
  	}
	echo "</table>\n";
	return 1;
    }
    return 0;
}

#
# Display template metadata and values in a table
#
function SHOWTEMPLATEMETADATA($guid, $version)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_metadata ".
		     "where template_guid='$guid' and ".
		     "      template_vers='$version'");

    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Template Metadata</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

 	echo "<tr>
                <th>Edit</th>
                <th>Name</th>
                <th>Value</th>
              </tr>\n";

	while ($row = mysql_fetch_array($query_result)) {
	    $name	   = $row['name'];
	    $value	   = $row['value'];
	    $metadata_guid = $row['guid'];
	    $metadata_vers = $row['vers'];
	    if (!isset($value)) {
		$value = "&nbsp";
	    }

	    echo "<tr>
   	           <td align=center>
                     <a href='template_metadata.php?action=modify".
		        "&guid=$metadata_guid&version=$metadata_vers'>
                     <img border=0 alt='modify' src='greenball.gif'></A></td>
                   <td>$name</td>
                   <td>$value</td>
                  </tr>\n";
  	}
	echo "</table>\n";
	return 1;
    }
    return 0;
}

#
# Display template instance binding values in a table
#
function SHOWTEMPLATEINSTANCEBINDINGS($guid, $version, $exptidx)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_instance_bindings ".
		     "where parent_guid='$guid' and parent_vers='$version' ".
		     "      and exptidx='$exptidx'");


    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Template Instance Bindings</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

 	echo "<tr>
                <th>Name</th>
                <th>Value</th>
              </tr>\n";

	while ($row = mysql_fetch_array($query_result)) {
	    $name	= $row['name'];
	    $value	= $row['value'];
	    if (!isset($value)) {
		$value = "&nbsp";
	    }

	    echo "<tr>
                   <td>$name</td>
                   <td>$value</td>
                  </tr>\n";
  	}
	echo "</table>\n";
	return 1;
    }
    return 0;
}

#
# Display a list of templates in its own table. Optional 
#
function SHOWTEMPLATELIST($which, $all, $myuid, $id, $gid = "")
{
    $extraclause = ($all ? "" : "and parent_guid is null");
	
    if ($which == "USER") {
	$where = "t.uid='$id'";
	$title = "Current";
    }
    elseif ($which == "PROJ") {
	$where = "t.pid='$id'";
	$title = "Project";
    }
    elseif ($which == "GROUP") {
	$where = "t.pid='$id' and t.gid='$gid'";
	$title = "Group";
    }
    elseif ($which == "TEMPLATE") {
	$where = "t.guid='$id' or t.parent_guid='$id'";
	$title = "Template";
    }
    else {
	$where = "1";
    }

    if (ISADMIN()) {
	$query_result =
	    DBQueryFatal("select t.* from experiment_templates as t ".
			 "where ($where) $extraclause ".
			 "order by t.pid,t.tid,t.created ");
    }
    else {
	$query_result =
	    DBQueryFatal("select t.* from experiment_templates as t ".
			 "left join group_membership as g on g.pid=t.pid and ".
			 "     g.gid=t.gid and g.uid='$myuid' ".
			 "where g.uid is not null and ($where) $extraclause ".
			 "order by t.pid,t.tid,t.created");
    }

    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Experiment Templates</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

 	echo "<tr>
                <th>GUID</th>
                <th>TID</th>
                <th>PID/GID</th>
              </tr>\n";

	while ($row = mysql_fetch_array($query_result)) {
	    $guid	= $row['guid'];
	    $pid	= $row['pid'];
	    $gid	= $row['gid'];
	    $tid	= $row['tid'];
	    $vers       = $row['vers'];

	    echo "<tr>
                   <td>" . MakeLink("template",
				    "guid=$guid&version=$vers", "$guid/$vers")
		      . "</td>
                   <td>$tid</td>
                   <td>" . MakeLink("project", "pid=$pid", "$pid/$gid") ."</td>
                  </tr>\n";
  	}
	echo "</table>\n";
    }
}

#
# Show the instance list for a template.
#
function SHOWTEMPLATEINSTANCES($guid, $version)
{
    $query_result =
	DBQueryFatal("select e.*,count(r.node_id) as nodes, ".
		     "    round(minimum_nodes+.1,0) as min_nodes ".
		     "from experiment_template_instances as i ".
		     "left join experiments as e on e.idx=i.exptidx ".
		     "left join reserved as r on e.pid=r.pid and ".
		     "     e.eid=r.eid ".
		     "where e.pid is not null and ".
		     "      (i.parent_guid='$guid' and ".
		     "       i.parent_vers='$version') ".
		     "group by e.pid,e.eid order by e.state,e.eid");

    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Template Instances for $guid/$version</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

	echo "<tr>
               <th>EID</th>
               <th>State</th>
               <th align=center>Nodes [1]</th>
               <th align=center>Hours Idle [2]</th>
              </tr>\n";

	$idlemark = "<b>*</b>";
	$stalemark = "<b>?</b>";
	
	while ($row = mysql_fetch_array($query_result)) {
	    $pid       = $row['pid'];
	    $eid       = $row['eid'];
	    $state     = $row['state'];
	    $nodes     = $row['nodes'];
	    $minnodes  = $row['min_nodes'];
	    $idlehours = TBGetExptIdleTime($pid, $eid);
	    $stale     = TBGetExptIdleStale($pid, $eid);
	    $ignore    = $row['idle_ignore'];
	    $name      = $row['expt_name'];
	    
	    if ($nodes == 0) {
		$nodes = "<font color=green>$minnodes</font>";
	    }
	    elseif ($row[swap_requests] > 0) {
		$nodes .= $idlemark;
	    }

	    $idlestr = $idlehours;
	    
	    if ($idlehours > 0) {
		if ($stale) {
		    $idlestr .= $stalemark;
		}
		if ($ignore) {
		    $idlestr = "($idlestr)";
		}
	    }
	    elseif ($idlehours == -1) {
		$idlestr = "&nbsp;";
	    }
	    
	    echo "<tr>
                   <td><A href='showexp.php3?pid=$pid&eid=$eid'>$eid</A></td>
  		   <td>$state</td>
                   <td align=center>$nodes</td>
                   <td align=center>$idlestr</td>
                 </tr>\n";
	}
	echo "</table>\n";
    }
}

#
# Show the historical instance list for a template.
#
function SHOWTEMPLATEHISTORY($guid, $version)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_instances as i ".
		     "where (i.parent_guid='$guid' and ".
		     "       i.parent_vers='$version') ".
		     "order by i.start_time");

    if (mysql_num_rows($query_result)) {
	echo "<center>
               <h3>Template History</h3>
             </center> 
             <table align=center border=1 cellpadding=5 cellspacing=2>\n";

	echo "<tr>
               <th>EID</th>
               <th>UID</th>
               <th>Start Time</th>
               <th>Stop Time</th>
              </tr>\n";

	$idlemark = "<b>*</b>";
	$stalemark = "<b>?</b>";
	
	while ($row = mysql_fetch_array($query_result)) {
	    $pid       = $row['pid'];
	    $eid       = $row['eid'];
	    $uid       = $row['uid'];
	    $start     = $row['start_time'];
	    $stop      = $row['stop_time'];

	    if (! isset($stop)) {
		$stop = "&nbsp";
	    }
	    
	    echo "<tr>
                   <td>$eid</td>
  		   <td>$uid</td>
                   <td>$start</td>
                   <td>$stop</td>
                 </tr>\n";
	}
	echo "</table>\n";
    }
}

#
# Display a metadata item in its own table.
#
function SHOWMETADATAITEM($guid, $version)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_metadata ".
		     "where guid='$guid' and vers='$version'");

    if (!mysql_num_rows($query_result)) {
	USERERROR("Experiment Template Metadata $guid/$version is no longer ".
		  "a valid template!", 1);
    }

    $row = mysql_fetch_array($query_result);

    #
    # Generate the table.
    #
    echo "<table align=center cellpadding=2 cellspacing=2 border=1>\n";
    
    ShowItem("GUID",
	     MakeLink("metadata",
		      "action=show&guid=$guid&version=$version",
		      "$guid/$version"));
    ShowItem("Name",        $row['name']);
    ShowItem("Value",       $row['value']);
    ShowItem("Created",     $row['created']);

    $template_guid = $row['template_guid'];
    $template_vers = $row['template_vers'];
    ShowItem("Template",
	     MakeLink("template",
		      "guid=$template_guid&version=$template_vers",
		      "$template_guid/$template_vers"));
    
    if (isset($row['parent_guid'])) {
	$parent_guid = $row['parent_guid'];
	$parent_vers = $row['parent_vers'];
	ShowItem("Parent Version",
		 MakeLink("metadata",
			  "action=show&guid=$parent_guid&version=$parent_vers",
			  "$parent_guid/$parent_vers"));
    }
    echo "</table>\n";
}

#
# Dump the image map for a template to the output.
#
function SHOWTEMPLATEGRAPH($guid)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_graphs ".
		     "where parent_guid='$guid'");

    if (!mysql_num_rows($query_result)) {
	USERERROR("Experiment Template graph for $guid is no longer ".
		  "in the DB!", 1);
    }
    $row = mysql_fetch_array($query_result);

    $imap = $row['imap'];

    echo "<center>
           <h3>Template Graph</h3>\n";
    echo $imap;
    echo "<img border=1 usemap=\"#TemplateGraph\" ";
    echo "     src='template_graph.php?guid=$guid'>\n";
    echo "</center>\n";
}

#
# Map pid/tid to a template guid. This only makes sense after a new
# template is created. Needs more thought.
#
function TBPidTid2Template($pid, $tid, &$guid, &$version)
{
    $query_result =
	DBQueryFatal("select * from experiment_templates ".
		     "where pid='$pid' and tid='$tid'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $guid    = $row['guid'];
    $version = $row['vers'];
    return 1;
}

#
# Map guid to pid/gid.
#
function TBGuid2PidGid($guid, &$pid, &$gid)
{
    $query_result =
	DBQueryFatal("select pid,gid from experiment_templates ".
		     "where guid='$guid' limit 1");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $pid = $row['pid'];
    $gid = $row['gid'];
    return 1;
}

#
# Map guid/version to its underlying experiment.
#
function TBTemplatePidEid($guid, $version, &$pid, &$eid)
{
    $query_result =
	DBQueryFatal("select pid from experiment_templates ".
		     "where guid='$guid' and vers='$version'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $pid = $row['pid'];
    $eid = "T${guid}-${version}";
    return 1;
}

#
# Map guid/version to the template tid.
#
function TBTemplateTid($guid, $version, &$tid)
{
    $query_result =
	DBQueryFatal("select tid from experiment_templates ".
		     "where guid='$guid' and vers='$version'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $tid = $row['tid'];
    return 1;
}

#
# Grab array of input files for a template, indexed by input_idx.
#
function TBTemplateInputFiles($guid, $version)
{
    $input_list = array();

    $query_result =
	DBQueryFatal("select * from experiment_template_inputs ".
		     "where parent_guid='$guid' and parent_vers='$version'");

    while ($row = mysql_fetch_array($query_result)) {
	$input_idx = $row['input_idx'];

	$input_query =
	    DBQueryFatal("select input from experiment_template_input_data ".
			 "where idx='$input_idx'");

	$input_row = mysql_fetch_array($input_query);
	$input_list["$input_idx"] = $input_row['input'];
    }
    return $input_list;
}

#
# Find out if an experiment is a template instantiation; used by existing
# pages to alter what they do.
#
function TBIsTemplateInstanceExperiment($exptidx)
{
    $query_result =
	DBQueryFatal("select pid,eid from experiment_template_instances ".
		     "where exptidx='$exptidx'");

    return mysql_num_rows($query_result);
}

#
# Map pid/eid to a template guid.
#
function TBPidEid2Template($pid, $eid, &$guid, &$version)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_instances ".
		     "where pid='$pid' and eid='$eid'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $guid    = $row['parent_guid'];
    $version = $row['parent_vers'];
    return 1;
}

#
# Map metadata to its template
#
function TBMetadata2Template($metadata_guid, $metadata_version,
			     &$template_guid, &$template_version)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_metadata ".
		     "where guid='$metadata_guid' and ".
		     "      vers='$metadata_version'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $template_guid    = $row['template_guid'];
    $template_version = $row['template_vers'];
    return 1;
}


#
# Return array of metadata data.
#
function TBMetadataData($metadata_guid, $metadata_version, &$metadata_data)
{
    $query_result =
	DBQueryFatal("select * from experiment_template_metadata ".
		     "where guid='$metadata_guid' and ".
		     "      vers='$metadata_version'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $metadata_data = mysql_fetch_array($query_result);
    return 1;
}

#
# Get a metadata value given a name and a template. 
#
function TBTemplateMetadataLookup($template_guid, $template_version,
				  $metadata_name, &$metadata_value)
{
    $query_result =
	DBQueryFatal("select value from experiment_template_metadata ".
		     "where template_guid='$template_guid' and ".
		     "      template_vers='$template_version' and ".
		     "      name='$metadata_name'");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    $row = mysql_fetch_array($query_result);
    $metadata_value = $row['value'];
    return 1;
}

#
# Return an array of the formal parameters for a template.
#
function TBTemplateFormalParameters($guid, $version, &$parameters)
{
    $parameters = array();

    if (!TBTemplatePidEid($guid, $version, &$pid, &$eid))
	return -1;
    
    $query_result =
	DBQueryFatal("select * from virt_parameters ".
		     "where pid='$pid' and eid='$eid'");

    while ($row = mysql_fetch_array($query_result)) {
	$name	= $row['name'];
	$value	= $row['value'];

	$parameters[$name] = $value;
    }
    return 0;
}

#
# Return an array of the bindings for a template instance.
#
function TBTemplateInstanceBindings($guid, $version, $exptidx, &$bindings)
{
    $bindings = array();

    $query_result =
	DBQueryFatal("select * from experiment_template_instance_bindings ".
		     "where parent_guid='$guid' and parent_vers='$version' ".
		     "      and exptidx='$exptidx'");

    while ($row = mysql_fetch_array($query_result)) {
	$name	= $row['name'];
	$value	= $row['value'];

	$bindings[$name] = $value;
    }
    return 0;
}

#
# Confirm a valid experiment template instance
#
# usage TBValidExperimentTemplateInstance($guid, $version, $exptidx)
#       returns 1 if valid
#       returns 0 if not valid
#
function TBValidExperimentTemplateInstance($guid, $version, $exptidx)
{
    $guid    = addslashes($guid);
    $version = addslashes($version);
    $exptidx = addslashes($exptidx);

    $query_result =
	DBQueryFatal("select guid from experiment_template_instances as i ".
		     "left join experiments as e on e.idx=i.exptidx ".
		     "where (i.parent_guid='$guid' and ".
		     "       i.parent_vers='$version' and ".
		     "       i.exptidx='$exptidx') and ".
		     "      (e.eid is not null and e.state='active')");

    if (mysql_num_rows($query_result) == 0) {
	return 0;
    }
    return 1;
}

#
# Slot checking support
#
function TBvalid_template_description($token) {
    return TBcheck_dbslot($token, "experiment_templates", "description",
			  TBDB_CHECKDBSLOT_WARN|TBDB_CHECKDBSLOT_ERROR);
}
function TBvalid_guid($token) {
    return TBcheck_dbslot($token, "experiment_templates", "guid",
			  TBDB_CHECKDBSLOT_WARN|TBDB_CHECKDBSLOT_ERROR);
}
function TBvalid_template_metadata_name($token) {
    return TBcheck_dbslot($token, "experiment_template_metadata", "name",
			  TBDB_CHECKDBSLOT_WARN|TBDB_CHECKDBSLOT_ERROR);
}
function TBvalid_template_metadata_value($token) {
    return TBcheck_dbslot($token, "experiment_template_metadata", "value",
			  TBDB_CHECKDBSLOT_WARN|TBDB_CHECKDBSLOT_ERROR);
}

?>
