<?php
include("defs.php3");

#
# Standard Testbed Header
#
PAGEHEADER("Begin a new Testbed Experiment");

#
# Only known and logged in users can begin experiments.
#
$uid = GETLOGIN();
LOGGEDINORDIE($uid);

#
# See what projects the uid is a member of. Must be at least one!
# 
$query_result = mysql_db_query($TBDBNAME,
	"SELECT pid FROM proj_memb WHERE uid=\"$uid\" ".
	"and (trust='local_root' or trust='group_root')");
    
if (! $query_result) {
    $err = mysql_error();
    TBERROR("Database Error finding project membership: $uid: $err\n", 1);
}
if (mysql_num_rows($query_result) == 0) {
    USERERROR("You do not appear to be a member of any Projects in which ".
	      "you have permission (root) to create new experiments.", 1);
}

?>
<table align="center" border="1"> 

<tr>
    <td align="center" colspan="3">
        <em>(Fields marked with * are required)</em>
    </td>
</tr>

<?php
echo "<form enctype=\"multipart/form-data\"
            action=\"beginexp_process.php3\" method=\"post\">\n";

#
# Select Project
#
echo "<tr>
          <td colspan=2>*Select Project:</td>";
echo "    <td><select name=\"exp_pid\">";
               while ($row = mysql_fetch_array($query_result)) {
                  $project = $row[pid];
                  echo "<option value=\"$project\">$project</option>\n";
               }
echo "       </select>";
echo "    </td>
      </tr>\n";

#
# Experiment ID and Long Name:
#
# Note DB max length.
#
echo "<tr>
          <td colspan=2>*Name (no blanks):</td>
          <td><input type=\"text\" name=\"exp_id\"
                     size=$TBDB_EIDLEN maxlength=$TBDB_EIDLEN>
              </td>
      </tr>\n";

echo "<tr>
          <td colspan=2>*Long Name (description):</td>
          <td><input type=\"text\" name=\"exp_name\" size=\"40\">
              </td>
      </tr>\n";


#
# NS file upload.
# 
echo "<tr>
          <td rowspan>*Your NS file: &nbsp</td>

          <td rowspan><center>Upload (20K max)<br>
                                   <br>
                                   Or<br>
                                   <br>
                              On Server (/proj or /users)
                      </center></td>

          <td rowspan>
              <input type=\"hidden\" name=\"MAX_FILE_SIZE\" value=\"20000\">
              <input type=\"file\" name=\"exp_nsfile\" size=\"30\">
              <br>
              <br>
              <input type=\"text\" name=\"exp_localnsfile\" size=\"40\">
              </td>
      </tr>\n";

#
# Expires, Starts, Ends. Also the hidden Created field.
#
$utime     = time();
$year      = date("Y", $utime);
$month     = date("m", $utime);
$thismonth = $month++;
if ($month > 12) {
	$month -= 12;
	$month = "0".$month;
}
$rest = date("d H:i:s", $utime);

echo "<tr>
          <td colspan=2>Expiration date:</td>
          <td><input type=\"text\" value=\"$year:$month:$rest\"
                     name=\"exp_expires\"></td>
     </tr>\n";

echo "<tr>
          <td colspan=2>Experiment starts:</td>
          <td><input type=\"text\" value=\"$year:$thismonth:$rest\"
                     name=\"exp_start\"></td>
	  <td><input type=\"hidden\" value=\"$year:$thismonth:$rest\"
                     name=\"exp_created\"></td>
          
     </tr>\n";

echo "<tr>
	  <td colspan=2>Experiment ends:</td>
          <td><input type=\"text\" value=\"$year:$month:$rest\"
                     name=\"exp_end\"></td>
     </tr>\n";

echo "<tr>
	  <td colspan=2>Pool Experiment?:<br>
                        (Leave unchecked unless you know what this means!)</td>
          <td><input type=checkbox name=exp_shared value=Yep>&nbsp</td>
     </tr>\n";
         
?>

<tr>
    <td align="center" colspan="3">
        <b><input type="submit" value="Submit"></b></td>
</tr>
</form>
</table>

<p>
<ul>
<li> Please <a href="nscheck_form.php3">syntax check</a> your NS file first!
<li> If your NS file is using a custom OSID, you must
     <a href="newosid_form.php3">create the OSID first!</a>
<li>
     You can also view a <a href="showosid_list.php3"> list of OSIDs</a>
     that are available for you to use in your NS file.
</ul>    

<?php
#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
