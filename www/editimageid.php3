<?php
include("defs.php3");
include("showstuff.php3");

#
# Standard Testbed Header
#
PAGEHEADER("Edit ImageID Information");

#
# Only known and logged in users can end experiments.
#
$uid = GETLOGIN();
LOGGEDINORDIE($uid);

#
# Verify form arguments.
# 
if (!isset($imageid) ||
    strcmp($imageid, "") == 0) {
    USERERROR("You must provide an ImageID.", 1);
}

if (!TBValidImageID($imageid)) {
    USERERROR("The ImageID $imageid is not a valid ImageID.", 1);
}

#
# Verify permission.
#
if (!TBImageIDAccessCheck($uid, $imageid, $TB_IMAGEID_MODIFYINFO)) {
    USERERROR("You do not have permission to access ImageID $imageid.", 1);
}

#
# Sanitize values and create string pieces.
#
if (isset($description) && strcmp($description, "")) {
    $foo = addslashes($description);
    
    $description = "'$foo'";
}
else {
    $description = "NULL";
}

if (isset($magic) && strcmp($magic, "")) {
    $foo = addslashes($magic);
    
    $magic = "'$foo'";
}
else {
    $magic = "NULL";
}

if (isset($path) && strcmp($path, "")) {
    $foo = addslashes($path);

    if (strcmp($path, $foo)) {
	USERERROR("The path must not contain special characters!", 1);
    }
    $path = "'$path'";
}
else {
    $path = "NULL";
}
if (isset($loadaddr) && strcmp($loadaddr, "")) {
    $foo = addslashes($loadaddr);

    if (strcmp($loadaddr, $foo)) {
	USERERROR("The load address must not contain special characters!", 1);
    }
    $loadaddr = "'$loadaddr'";
}
else {
    $loadaddr = "NULL";
}

#
# Create an update string
#
$query_string =
	"UPDATE images SET             ".
	"description=$description,     ".
	"path=$path,                   ".
	"magic=$magic,                 ".
        "load_address=$loadaddr        ";

$query_string = "$query_string WHERE imageid='$imageid'";

$insert_result = DBQueryFatal($query_string);

SHOWIMAGEID($imageid, 0);

# Edit option.
$fooid = rawurlencode($imageid);
echo "<p><center>
       Do you want to edit this ImageID?
       <A href='editimageid_form.php3?imageid=$fooid'>Yes</a>
      </center>\n";

echo "<br><br>\n";

# Delete option.
echo "<p><center>
       Do you want to delete this ImageID?
       <A href='deleteimageid.php3?imageid=$fooid'>Yes</a>
      </center>\n";    

#
# Standard Testbed Footer
# 
PAGEFOOTER();
?>
