#!/usr/bin/perl -w
#
# EMULAB-COPYRIGHT
# Copyright (c) 2000-2003 University of Utah and the Flux Group.
# All rights reserved.
#
use English;
use Getopt::Std;
use Fcntl;
use IO::Handle;
use Socket;
use Fcntl ':flock';

# Drag in path stuff so we can find emulab stuff. Also untaints path.
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }

use libsetup qw(JailedNFSMounts REMOTE);

#
# Questions:
#
# * Whats the hostname for the jail? Perhaps vnodename.emulab.net
# * What should /etc/resolv.conf look like?
# 

#
# Create a jailed environment. There are some stub files stored in
# /etc/jail that copied into the jail.
#
sub usage()
{
    print("Usage: mkjail.pl [-s] [-i <ipaddr>] [-p <pid>] <hostname>\n");
    exit(-1);
}
my  $optlist = "i:p:e:s";

#
# Only real root can run this script.
#
if ($UID) {
    die("Must be root to run this script!\n");
}
system("sysctl jail.set_hostname_allowed=0 >/dev/null 2>&1");

#
# Catch ^C and exit with error. 
#
my $leaveme = 0;
sub handler ($) {
    my ($signame) = @_;
    
    $SIG{INT}  = 'IGNORE';
    $SIG{USR1} = 'IGNORE';
    $SIG{TERM} = 'IGNORE';
    $SIG{HUP}  = 'IGNORE';

    if ($signame eq 'USR1') {
	$leaveme = 1;
    }
    fatal("Caught a SIG${signame}! Killing the jail ...");
}
$SIG{INT}  = \&handler;
$SIG{USR1} = \&handler;
$SIG{HUP}  = \&handler;
$SIG{TERM} = 'IGNORE';

#
# Turn off line buffering on output
#
STDOUT->autoflush(1);
STDERR->autoflush(1);

#
# Locals
#
my $JAILPATH	= "/var/emulab/jails";
my $ETCJAIL     = "/etc/jail";
my $LOCALFS	= "/users/local";
my $LOCALMNTPNT = "/local";
my $TMCC	= "$BINDIR/tmcc";
my $JAILCONFIG  = "jailconfig";
my @ROOTCPDIRS	= ("etc", "root");
my @ROOTMKDIRS  = ("dev", "tmp", "var", "usr", "proc", "users", "opt",
		   "bin", "sbin", "home", $LOCALMNTPNT);
my @ROOTMNTDIRS = ("bin", "sbin", "usr");
my @EMUVARDIRS	= ("logs", "db", "jails", "boot", "lock");
my $VNFILEMBS   = 64;
my $MAXVNDEVS	= 10;
my $IP;
my $PID;
my $debug	= 1;
my $cleaning	= 0;
my $vndevice;
my @mntpoints   = ();
my $jailpid;
my $tmccpid;
my $interactive = 0;

# This stuff is passed from tmcd, which we parse into a config string
# and an option set.
my %jailconfig  = ();
my $jailoptions = " -o inaddrany -o routing -r -1";
my $sshdport    = 50000;	# Bogus default, good for testing.
my $routetabid  = 0;		# Default to main routing table.
my $jailflags   = 3;
my @jailips     = ();		# List of jail IPs (for routing table).
my $ipfwrules	= ();		# List of IPFW rules to clean.
my $JAIL_DEVMEM = 0x01;		# We need to know if these options given.
my $JAIL_ROUTING= 0x02;

#
# Parse command arguments. Once we return from getopts, all that should be
# left are the required arguments.
#
%options = ();
if (! getopts($optlist, \%options)) {
    usage();
}
if (@ARGV != 1) {
    usage();
}
my $HOST = $ARGV[0];

#
# Untaint the arguments.
#
if ($HOST =~ /^([-\w\/]+)$/) {
    $HOST = $1;
}
else {
    die("Tainted argument $HOST!\n");
}

if (defined($options{'s'})) {
    $interactive = 1;
}

#
# Get the parent IP.
# 
my $hostname = `hostname`;
my $hostip;

# Untaint and strip newline.
if ($hostname =~ /^([-\w\.]+)$/) {
    $hostname = $1;

    my (undef,undef,undef,undef,@ipaddrs) = gethostbyname($hostname);
    $hostip = inet_ntoa($ipaddrs[0]);
}

#
# If no IP, then it defaults to our hostname's IP.
# 
if (defined($options{'i'})) {
    $IP = $options{'i'};

    if ($IP =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
	$IP = $1;
    }
    else {
	die("Tainted argument $IP!\n");
    }
}
else {
    $IP = $hostip;
}
if (!defined($IP)) {
    usage();
}

if (defined($options{'p'})) {
    $PID = $options{'p'};

    if ($PID =~ /^([-\@\w]+)$/) {
	$PID = $1;
    }
    else {
	die("Tainted argument $PID.");
    }
}

print("Setting up jail for HOST:$HOST using IP:$IP\n")
    if ($debug);

#
# In most cases, the $HOST directory will have been created by the caller,
# and a config file possibly dropped in.
# When debugging, we have to create it here. 
# 
chdir($JAILPATH) or
    die("Could not chdir to $JAILPATH: $!\n");

if (! -e $HOST) {
    mkdir($HOST, 0770) or
	fatal("Could not mkdir $HOST in $JAILPATH: $!");
}
else {
    getjailconfig("$JAILPATH/$HOST");
}

#
# See if special options supported, and if so setup args as directed.
#
setjailoptions();

#
# Create the "disk";
#
if (-e "$HOST/root") {
    #
    # Try to pick up where we left off.
    # 
    restorerootfs("$JAILPATH/$HOST");
}
else {
    #
    # Create the root filesystem.
    #
    mkrootfs("$JAILPATH/$HOST");
}

#
# Start the tmcc proxy. This path will be valid in both the outer
# environment and in the jail!
#
startproxy("$JAILPATH/$HOST");

#
# Start the jail. We do it in a child so we can send a signal to the
# jailed process to force it to shutdown. The jail has to shut itself
# down.
#
$jailpid = fork();
if ($jailpid) {
    # We do not really care about the exit status of the jail.
    waitpid($jailpid, 0);
    undef($jailpid);
}
else {
    $SIG{TERM} = 'DEFAULT';
    $ENV{'TMCCVNODEID'} = $HOST;

    my $cmd = "jail $jailoptions ".
	"$JAILPATH/$HOST/root $HOST $IP /etc/jail/injail.pl";
    if ($interactive) {
	$cmd .= " /bin/csh";
    }
    exec($cmd);
    die("*** $0:\n".
	"    exec failed to start the jail!\n");
}
	 
#
# Once we exit, cleanup the mess.
#
cleanup();
exit(0);

#
# Create a file for a vnode device, vnconfig it, newfs, and then
# mount it on the "root" directory.
#
sub mkrootfs($)
{
    my ($path) = @_;
    my $vnsize = $VNFILEMBS;

    chdir($path) or
	fatal("Could not chdir to $path: $!");

    mkdir("root", 0770) or
	fatal("Could not mkdir 'root' in $path: $!");
    
    #
    # Big file of zeros.
    # 
    mysystem("dd if=/dev/zero of=root.vnode bs=1m count=$vnsize");

    #
    # Find a free vndevice.
    #
    for (my $i = 0; $i < $MAXVNDEVS; $i++) {
	# Make sure the dev entries exist!
	mysystem("(cd /dev; ./MAKEDEV vn${i})");
	
	system("vnconfig -c vn${i} root.vnode");
	if (! $?) {
	    $vndevice = $i;
	    last;
	}
    }
    fatal("Could not find a free vn device!") 
	if (!defined($vndevice));
    print("Using vn${vndevice}\n")
 	if ($debug);

    mysystem("vnconfig -s labels vn${vndevice} root.vnode");
    mysystem("disklabel -r -w vn${vndevice} auto");
    mysystem("newfs -b 8192 -f 1024 -i 4096 -c 15 /dev/vn${vndevice}c");
    mysystem("tunefs -m 2 -o space /dev/vn${vndevice}c");
    mysystem("mount /dev/vn${vndevice}c root");
    push(@mntpoints, "$path/root");

    #
    # Okay, copy in the top level directories. 
    #
    foreach my $dir (@ROOTCPDIRS) {
	mysystem("hier -f -FN cp /$dir root/$dir");
    }

    #
    # Make some other directories that are nice to have!
    #
    foreach my $dir (@ROOTMKDIRS) {
	mkdir("root/$dir", 0755) or
	    fatal("Could not mkdir '$dir' in $path/root: $!");
    }

    #
    # Okay, mount some other directories to save space.
    #
    foreach my $dir (@ROOTMNTDIRS) {
	mysystem("mount -r localhost:/$dir $path/root/$dir");
	push(@mntpoints, "$path/root/$dir");
    }

    #
    # The proc FS in the jail is per-jail of course.
    # 
    mysystem("mount -t procfs proc $path/root/proc");
    push(@mntpoints, "$path/root/proc");

    #
    # /tmp is special of course
    #
    mysystem("chmod 1777 root/tmp");

    #
    # /dev is also special. It gets a very restricted set of entries.
    # Note that we create some BPF devices since they work in our jails.
    #
    my $makedevs = "bpf31";
    if ($jailflags & $JAIL_DEVMEM) {
	$makedevs .= " std pty0";
    }
    else {
	$makedevs .= " jail";
    }
    mysystem("cd $path/root/dev; cp -p /dev/MAKEDEV .; ./MAKEDEV $makedevs");
    
    #
    # Create stub /var and create the necessary log files.
    #
    # NOTE: I stole this little diddy from /etc/rc.diskless2.
    #
    mysystem("mtree -nqdeU -f /etc/mtree/BSD.var.dist ".
	     "-p $path/root/var >/dev/null 2>&1");
    mysystem("mkdir -p $path/root/$path");

    #
    # Make the emulab directories since they are not in the mtree file.
    #
    if (! -e "$path/root/var/emulab") {
	mkdir("$path/root/var/emulab", 0755) or
	    fatal("Could not mkdir 'emulab' in $path/root/var: $!");
    }
    foreach my $dir (@EMUVARDIRS) {
	if (! -e "$path/root/var/emulab/$dir") {
	    mkdir("$path/root/var/emulab/$dir", 0755) or
		fatal("Could not mkdir 'dir' in $path/root/var/emulab: $!");
	}
    }

    #
    # Get a list of all the plain files and create zero length versions
    # in the new var.
    #
    opendir(DIR, "/var/log") or
	fatal("Cannot opendir /var/log: $!");
    my @logs = grep { -f "/var/log/$_" } readdir(DIR);
    closedir(DIR);

    foreach my $log (@logs) {
	mysystem("touch $path/root/var/log/$log");
    }

    #
    # Now a bunch of stuff to set up a nice environment in the jail.
    #
    mysystem("cp -p $ETCJAIL/rc.conf $path/root/etc");
    mysystem("rm -f $path/root/etc/rc.conf.local");
    mysystem("cp -p $ETCJAIL/rc.local $path/root/etc");
    mysystem("cp -p $ETCJAIL/group $path/root/etc");
    mysystem("cp -p $ETCJAIL/master.passwd $path/root/etc");
    mysystem("cp /dev/null $path/root/etc/fstab");
    mysystem("pwd_mkdb -p -d $path/root/etc $path/root/etc/master.passwd");
    mysystem("echo '$IP		$HOST' >> $path/root/etc/hosts");
    mysystem("echo 'sshd_flags=\"\$sshd_flags -p $sshdport\"' >> ".
	     " $path/root/etc/rc.conf");

    # No X11 forwarding. 
    mysystem("cat $path/root/etc/ssh/sshd_config | ".
	     "sed -e 's/^X11Forwarding.*yes/X11Forwarding no/' > ".
	     "$path/root/tmp/sshd_foo");
    mysystem("cp -f $path/root/tmp/sshd_foo $path/root/etc/ssh/sshd_config");

    # In the jail, 127.0.0.1 refers to the jail, but we want to use the
    # nameserver running *outside* the jail.
    mysystem("cat /etc/resolv.conf | ".
	     "sed -e 's/127\.0\.0\.1/$hostip/' > ".
	     "$path/root/etc/resolv.conf");

    #
    # If the jail gets its own routing table, must arrange for it to
    # be populated when the jail starts up.
    # 
    if ($jailflags & $JAIL_ROUTING) {
	addroutestorc("$path/root/etc/rc.conf");
    }
	
    #
    # Give the jail an NFS mount of the local project directory. This one
    # is read-write.
    #
    if (defined($PID) && -e $LOCALFS && -e "$LOCALFS/$PID") {
	mysystem("mkdir -p $path/root/$LOCALMNTPNT/$PID");
	mysystem("mount localhost:$LOCALFS/$PID $path/root/$LOCALMNTPNT/$PID");
	push(@mntpoints, "$path/root/$LOCALMNTPNT/$PID");
    }

    #
    # Ug. Until we have SFS working the way I want it, NFS mount the
    # usual directories inside the jail. This duplicates a lot of mounts,
    # but not sure what to do about that. 
    #
    if (! REMOTE()) {
	foreach my $dir ( JailedNFSMounts($HOST, "$path/root") ) {
	    push(@mntpoints, "$path/root/$dir");
	}
    }

    cleanmess($path);
    return 0;
}

#
# Restore a jail after a crash.
#
sub restorerootfs($)
{
    my ($path) = @_;

    chdir($path) or
	fatal("Could not chdir to $path: $!");

    #
    # Find a free vndevice.
    #
    for (my $i = 0; $i < $MAXVNDEVS; $i++) {
	# Make sure the dev entries exist!
	mysystem("(cd /dev; ./MAKEDEV vn${i})");
	
	system("vnconfig -c vn${i} root.vnode");
	if (! $?) {
	    $vndevice = $i;
	    last;
	}
    }
    fatal("Could not find a free vn device!") 
	if (!defined($vndevice));
    print("Using vn${vndevice}\n")
 	if ($debug);

    mysystem("vnconfig -s labels vn${vndevice} root.vnode");
    mysystem("fsck -y /dev/vn${vndevice}c");
    mysystem("mount /dev/vn${vndevice}c root");
    push(@mntpoints, "$path/root");

    #
    # Okay, mount some other directories to save space.
    #
    foreach my $dir (@ROOTMNTDIRS) {
	mysystem("mount -r localhost:/$dir $path/root/$dir");
	push(@mntpoints, "$path/root/$dir");
    }

    #
    # The proc FS in the jail is per-jail of course.
    # 
    mysystem("mount -t procfs proc $path/root/proc");
    push(@mntpoints, "$path/root/proc");

    #
    # Give the jail an NFS mount of the local project directory. This one
    # is read-write.
    #
    if (defined($PID) && -e $LOCALFS && -e "$LOCALFS/$PID") {
	mysystem("mkdir -p $path/root/$LOCALMNTPNT/$PID");
	mysystem("mount localhost:$LOCALFS/$PID $path/root/$LOCALMNTPNT/$PID");
	push(@mntpoints, "$path/root/$LOCALMNTPNT/$PID");
    }

    #
    # Ug. Until we have SFS working the way I want it, NFS mount the
    # usual directories inside the jail. This duplicates a lot of mounts,
    # but not sure what to do about that. 
    #
    if (! REMOTE()) {
	foreach my $dir ( JailedNFSMounts($HOST, "$path/root") ) {
	    push(@mntpoints, "$path/root/$dir");
	}
    }
    return 0;
}

#
# Okay, we clean up some of what is in /etc and /etc/emulab so that the
# jail cannot see that stuff. 
#
sub cleanmess($) {
    my ($path) = @_;

    #
    # And, some security stuff. We want to remove bits of stuff from the
    # jail that would enable it to talk to tmcd directly. 
    #
    mysystem("rm -f $path/root/etc/emulab.cdkey");
    mysystem("rm -f $path/root/etc/emulab.pkey");

    mysystem("rm -f  $path/root/$ETCDIR/*.pem");
    mysystem("rm -f  $path/root/$ETCDIR/cvsup.auth");
    mysystem("rm -rf $path/root/$ETCDIR/.cvsup");
    mysystem("rm -f  $path/root/$ETCDIR/master.passwd");

    #
    # Copy in emulabman if it exists.
    #
    if (my (undef,undef,undef,undef,undef,undef,undef,$dir) =
	getpwnam("emulabman")) {
	mysystem("hier cp $dir $path/root/home/emulabman");
    }
}

#
# Start the tmcc proxy and insert the unix path into the environment
# for the jail to pick up.
#
sub startproxy($)
{
    my ($dir) = @_;
    my $log   = "$dir/tmcc.log";

    #
    # The point of these paths is so that there is a comman path to
    # the socket both outside and inside the jail. Yuck!
    #
    my $insidepath  = "$dir/tmcc";
    my $outsidepath = "$dir/root/$insidepath";

    $tmccpid = fork();
    if ($tmccpid) {
	#
	# So tmcc will work nicely inside the jail without needing the
	# -l option specified all over.
	#
	$ENV{'TMCCUNIXPATH'} = $insidepath;
	
	select(undef, undef, undef, 0.2);
	return 0;
    }
    $SIG{TERM} = 'DEFAULT';

    # The -o option will cause the proxy to detach but not fork!
    # Eventually change this to standard pid file kill.
    exec("$TMCC -d -x $outsidepath -n $HOST -o $log");
    die("Exec of $TMCC failed! $!\n");
}

#
# Cleanup at exit.
#
sub cleanup()
{
    if ($cleaning) {
	die("*** $0:\n".
	    "    Oops, already cleaning!\n");
    }
    $cleaning = 1;
    
    #
    # Note that the unmounts will fail unless all the processes inside
    # the jail exit!
    # 
    if (defined($tmccpid)) {
	kill('TERM', $tmccpid);
	waitpid($tmccpid, 0);
    }

    if (defined($jailpid)) {
	kill('TERM', $jailpid);
	waitpid($jailpid, 0);
    }

    foreach my $ruleno (keys(%ipfwrules)) {
	system("ipfw delete $ruleno");
    }

    while (@mntpoints) {
	my $mntpoint = pop(@mntpoints);

	# If the umounts fail, we do want to continue. Dangerous!
	system("umount $mntpoint");
	if ($?) {
	    # Avoid recursive calls to cleanup; do not use fatal.
	    die("*** $0:\n".
		"    umount '$mntpoint' failed: $!\n");
	}
    }
    if (defined($vndevice)) {
	system("vnconfig -u vn${vndevice}");
    }
    if (!$leaveme) {
        #
        # Ug, with NFS mounts inside the jail, we need to be really careful.
        #
	if (-d "$JAILPATH/$HOST/root" && !rmdir("$JAILPATH/$HOST/root")) {
	    die("*** $0:\n".
		"    $JAILPATH/$HOST/root is not empty! This is very bad!\n");
	}
	system("rm -rf $JAILPATH/$HOST");
    }
}

#
# Print error and exit.
#
sub fatal($)
{
    my ($msg) = @_;

    cleanup();
    die("*** $0:\n".
	"    $msg\n");
}

#
# Run a command string, redirecting output to a logfile.
#
sub mysystem($)
{
    my ($command) = @_;

    system($command);
    if ($?) {
	fatal("Command failed: $? - $command");
    }
}

#
# Read in the jail config file. 
#
sub getjailconfig($)
{
    my ($path) = @_;

    $path .= "/$JAILCONFIG";

    if (! -e $path) {
	return 0;
    }
    
    if (! open(CONFIG, $path)) {
	print("$path could not be opened for reading: $!\n");
	return -1;
    }
    while (<CONFIG>) {
	if ($_ =~ /^(.*)="(.+)"$/ ||
	    $_ =~ /^(.*)=(.+)$/) {
	    $jailconfig{$1} = $2;
	}
    }
    close(CONFIG);
    return 0;
}

#
# See if special jail opts supported.
#
sub setjailoptions() {
    #
    # Do this all the time, so that we can figure out the sshd port.
    # 
    foreach my $key (keys(%jailconfig)) {
	my $val = $jailconfig{$key};

        SWITCH: for ($key) {
	    /^PORTRANGE$/ && do {
		if ($val =~ /(\d+),(\d+)/) {
		    $jailoptions .= " -p $1:$2";
		}
		last SWITCH;
	    };
	    /^SSHDPORT$/ && do {
		if ($val =~ /(\d+)/) {
		    $sshdport     = $1;
		}
		last SWITCH;
	    };
	    /^SYSVIPC$/ && do {
		if ($val) {
		    $jailoptions .= " -o sysvipc";
		}
		else {
		    $jailoptions .= " -o nosysvipc";
		}
		last SWITCH;
	    };
	    /^INETRAW$/ && do {
		if ($val) {
		    $jailoptions .= " -o inetraw";
		}
		else {
		    $jailoptions .= " -o noinetraw";
		}
		last SWITCH;
	    };
	    /^BPFRO$/ && do {
		if ($val) {
		    $jailoptions .= " -o bpfro";
		}
		else {
		    $jailoptions .= " -o nobpfro";
		}
		last SWITCH;
	    };
	    /^INADDRANY$/ && do {
		if ($val) {
		    $jailoptions .= " -o inaddrany";
		}
		else {
		    $jailoptions .= " -o noinaddrany";
		}
		last SWITCH;
	    };
	    /^ROUTING$/ && do {
		if ($val) {
		    $jailoptions .= " -o routing";

		    $jailflags |= $JAIL_ROUTING;
		    #
		    # If the jail gets routing privs, then it must get
		    # its own routing table. We need to know this number
		    # so we can enter an ipfw rule for it.
		    #
		    $routetabid   = getnextrtabid();
		    $jailoptions .= " -r $routetabid";
		}
		else {
		    $jailoptions .= " -o norouting";
		}
		last SWITCH;
	    };
	    /^DEVMEM$/ && do {
		$jailflags |= $JAIL_DEVMEM;
		last SWITCH;
	    };
 	    /^IPADDRS$/ && do {
		# Comma separated list of IPs
		my @iplist = split(",", $val);

		foreach my $ip (@iplist) {
		    if ($ip =~ /(\d+\.\d+\.\d+\.\d+)/) {
			$jailoptions .= " -i $1";
			push(@jailips, $1);
		    }
		}
 		last SWITCH;
 	    };
	}
    }
    print("SSHD port is $sshdport\n");

    system("sysctl jail.inetraw_allowed=1 >/dev/null 2>&1");
    system("sysctl jail.bpf_allowed=1 >/dev/null 2>&1");
    system("sysctl jail.inaddrany_allowed=1 >/dev/null 2>&1");
    system("sysctl jail.multiip_allowed=1 >/dev/null 2>&1");
    system("sysctl net.link.ether.inet.useloopback=0 >/dev/null 2>&1");

    if ($?) {
	print("Special jail options are NOT supported!\n");
	$jailoptions = "";
	$jailflags   = 0;
	return 0;
    }
    print("Special jail options are supported: '$jailoptions'\n");

    if (@jailips && ($jailflags & $JAIL_ROUTING)) {
	genipfwrules();
    }
    return 0;
}

#
# Append a list of static routes to the rc.conf file.
#
sub addroutestorc($rc)
{
    my ($rc)   = @_;
    my $count  = 0;

    #
    # Need the IP of the default router, which we got from DHCP but
    # is not stashed anyplace easy to get at. 
    # 
    my $router_name = `route get default | awk '/gateway:/ {print \$2}'`;
    chomp($router_name);
    my (undef,undef,undef,undef,@ipaddrs) = gethostbyname($router_name);
    my $router_ip = inet_ntoa($ipaddrs[0]);
    fatal("Could not determine IP of the default router!")
	if (!defined($router_ip));

    open(RC, ">>$rc") or
	fatal("Could not open $rc to append static routes");

    #
    # First the set of routes that all jails get. 
    # 
    print RC "static_routes=\"default lo0 host\"\n";
    print RC "route_default=\"default $router_ip\"\n";
    print RC "route_lo0=\"localhost -interface lo0\"\n";
    print RC "route_host=\"$hostip localhost\"\n";

    #
    # Now a list of routes for each of the IPs the jail has access
    # to. Of course, we need to know the interface name, so use the
    # route command again.
    # 
    foreach my $ip (@jailips) {
	my $interface = `route get $ip | awk '/interface:/ {print \$2}'`;
	my $netmask   = `route get $ip | awk '/mask:/ {print \$2}'`;
	chomp($interface);
	chomp($netmask);
	fatal("Could not find interface for $ip")
	    if (!defined($interface));

	print RC "static_routes=\"ip${count} \$static_routes\"\n";
	print RC "route_ip${count}=\"-net $ip -interface $interface " .
	    "-netmask $netmask\"\n";

	$count++;
    }
    close(RC);
    return 0;
}

#
# Ug, with NFS mounts inside the jail, we need to be really careful.
#
sub removevnodedir($)
{
    my ($dir) = @_;

    if (-d "$dir/root" && !rmdir("$dir/root")) {
	die("*** $0:\n".
	    "    $dir/root is not empty! This is very bad!\n");
    }
    system("rm -rf $dir");
}

#
# Get a free routing table ID. This should eventually come from the
# kernel, but for now just use a file with a number in it. 
#
sub getnextrtabid()
{
    my $nextrtabid = 1;

    #
    # The chances of a race are low, but need to deal with it anyway.
    #
    my $lockfile  = "/var/emulab/lock/rtabid";
    my $rtabidfile= "/var/emulab/db/rtabid";

    open(LOCK, ">>$lockfile") ||
	fatal("Could not open $lockfile\n");
    
    while (flock(LOCK, LOCK_EX|LOCK_NB) == 0) {
	print "Waiting to get lock for $lockfile\n";
	sleep(1);
    }
    if (-e $rtabidfile) {
	my $rtabid = `cat $rtabidfile`;
	if ($rtabid =~ /^(\d*)$/) {
	    $nextrtabid = $1 + 1;
	}
	else {
	    close(LOCK);
	    fatal("Bad data in $rtabidfile!");
	}
    }
    system("echo $nextrtabid > $rtabidfile");
    close(LOCK);
    return $nextrtabid;
}

#
# Generate the list of ipfw rules for setting the rtabid. This should
# eventually go away when we have better support in the kernel for
# figuring this out.
#
sub genipfwrules()
{
    my $index = $routetabid * 100;

    if (scalar(@jailips) > 100) {
	fatal("Too many ipfw rules (too many IPs)!");
    }

    foreach my $ip (@jailips) {
	my $rule = "ipfw add $index rtabid $routetabid ip from any to $ip";

	#
	# Install rule. If any fail, we are doomed.
	#
	system($rule) == 0
	    or fatal("ipfw failed: $rule");
	
	#
	# Save for cleanup().
	# 
	$ipfwrules{$index++} = $rule;
    }
}
